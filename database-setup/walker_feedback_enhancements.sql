-- Walker Agent Feedback Collection Enhancements
-- This migration adds conversation-end feedback tracking and ensures proper indexing
-- Execute using: psql $DATABASE_PUBLIC_URL -f walker_feedback_enhancements.sql

-- ============================================================================
-- 1. Add conversation_end_feedback_requested to chat_sessions
-- ============================================================================
-- Tracks if feedback has been requested at conversation end
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'chat_sessions'
        AND column_name = 'feedback_requested_at'
    ) THEN
        ALTER TABLE chat_sessions
        ADD COLUMN feedback_requested_at TIMESTAMP;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'chat_sessions'
        AND column_name = 'feedback_submitted_at'
    ) THEN
        ALTER TABLE chat_sessions
        ADD COLUMN feedback_submitted_at TIMESTAMP;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'chat_sessions'
        AND column_name = 'conversation_rating'
    ) THEN
        ALTER TABLE chat_sessions
        ADD COLUMN conversation_rating INTEGER CHECK (conversation_rating >= 1 AND conversation_rating <= 5);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'chat_sessions'
        AND column_name = 'conversation_feedback'
    ) THEN
        ALTER TABLE chat_sessions
        ADD COLUMN conversation_feedback TEXT;
    END IF;
END $$;

COMMENT ON COLUMN chat_sessions.feedback_requested_at IS 'Timestamp when feedback was requested at conversation end';
COMMENT ON COLUMN chat_sessions.feedback_submitted_at IS 'Timestamp when user submitted feedback';
COMMENT ON COLUMN chat_sessions.conversation_rating IS 'Overall conversation rating (1-5 stars)';
COMMENT ON COLUMN chat_sessions.conversation_feedback IS 'User feedback comments for the conversation';

-- ============================================================================
-- 2. Create conversation_feedback_metrics view for analytics
-- ============================================================================
CREATE OR REPLACE VIEW conversation_feedback_metrics AS
SELECT
    cs.tenant_id,
    cs.session_type,
    COUNT(DISTINCT cs.id) as total_conversations,
    COUNT(DISTINCT CASE WHEN cs.feedback_requested_at IS NOT NULL THEN cs.id END) as feedback_requested_count,
    COUNT(DISTINCT CASE WHEN cs.feedback_submitted_at IS NOT NULL THEN cs.id END) as feedback_submitted_count,
    ROUND(
        COUNT(DISTINCT CASE WHEN cs.feedback_submitted_at IS NOT NULL THEN cs.id END)::NUMERIC /
        NULLIF(COUNT(DISTINCT CASE WHEN cs.feedback_requested_at IS NOT NULL THEN cs.id END), 0) * 100,
        2
    ) as feedback_response_rate,
    ROUND(AVG(cs.conversation_rating), 2) as average_rating,
    COUNT(DISTINCT CASE WHEN cs.conversation_rating = 5 THEN cs.id END) as five_star_count,
    COUNT(DISTINCT CASE WHEN cs.conversation_rating = 4 THEN cs.id END) as four_star_count,
    COUNT(DISTINCT CASE WHEN cs.conversation_rating = 3 THEN cs.id END) as three_star_count,
    COUNT(DISTINCT CASE WHEN cs.conversation_rating = 2 THEN cs.id END) as two_star_count,
    COUNT(DISTINCT CASE WHEN cs.conversation_rating = 1 THEN cs.id END) as one_star_count,
    MIN(cs.created_at) as first_conversation_date,
    MAX(cs.created_at) as last_conversation_date
FROM chat_sessions cs
WHERE cs.is_active = false -- Only completed conversations
GROUP BY cs.tenant_id, cs.session_type;

COMMENT ON VIEW conversation_feedback_metrics IS 'Aggregated feedback metrics by tenant and session type';

-- ============================================================================
-- 3. Create agent_performance_with_feedback view
-- ============================================================================
CREATE OR REPLACE VIEW agent_performance_with_feedback AS
SELECT
    aa.id as agent_id,
    aa.tenant_id,
    aa.name as agent_name,
    aa.agent_type,
    aa.agent_category,
    aa.total_executions,
    aa.successful_executions,
    aa.rating_average as marketplace_rating,
    aa.rating_count as marketplace_rating_count,
    -- Conversation feedback metrics
    COUNT(DISTINCT cs.id) as total_conversations,
    COUNT(DISTINCT CASE WHEN cs.feedback_submitted_at IS NOT NULL THEN cs.id END) as conversations_with_feedback,
    ROUND(AVG(cs.conversation_rating), 2) as conversation_avg_rating,
    -- Customer satisfaction metrics
    COUNT(DISTINCT csf.id) as satisfaction_feedback_count,
    ROUND(AVG(csf.rating), 2) as satisfaction_avg_rating,
    COUNT(DISTINCT CASE WHEN csf.would_recommend = true THEN csf.id END) as would_recommend_count,
    COUNT(DISTINCT CASE WHEN csf.sentiment = 'positive' THEN csf.id END) as positive_sentiment_count,
    COUNT(DISTINCT CASE WHEN csf.sentiment = 'neutral' THEN csf.id END) as neutral_sentiment_count,
    COUNT(DISTINCT CASE WHEN csf.sentiment = 'negative' THEN csf.id END) as negative_sentiment_count,
    -- Agent feedback loops
    COUNT(DISTINCT afl.id) as feedback_loop_count,
    COUNT(DISTINCT CASE WHEN afl.applied_to_model = true THEN afl.id END) as applied_feedback_count,
    ROUND(AVG(afl.impact_score), 4) as avg_feedback_impact,
    -- Timestamps
    MAX(cs.last_activity_at) as last_conversation_at,
    MAX(csf.created_at) as last_satisfaction_feedback_at
FROM ai_agents aa
LEFT JOIN chat_sessions cs ON cs.tenant_id = aa.tenant_id
LEFT JOIN customer_satisfaction_feedback csf ON csf.tenant_id = aa.tenant_id AND csf.agent_type = aa.agent_type
LEFT JOIN agent_feedback_loops afl ON afl.agent_id = aa.id
WHERE aa.agent_category = 'walker' -- Walker agents only
GROUP BY aa.id, aa.tenant_id, aa.name, aa.agent_type, aa.agent_category,
         aa.total_executions, aa.successful_executions, aa.rating_average, aa.rating_count;

COMMENT ON VIEW agent_performance_with_feedback IS 'Comprehensive view of Walker agent performance including all feedback sources';

-- ============================================================================
-- 4. Add indexes for performance optimization
-- ============================================================================
CREATE INDEX IF NOT EXISTS idx_chat_sessions_feedback_requested
ON chat_sessions(tenant_id, feedback_requested_at)
WHERE feedback_requested_at IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_chat_sessions_feedback_submitted
ON chat_sessions(tenant_id, feedback_submitted_at)
WHERE feedback_submitted_at IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_chat_sessions_rating
ON chat_sessions(tenant_id, conversation_rating)
WHERE conversation_rating IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_customer_satisfaction_conversation
ON customer_satisfaction_feedback(conversation_id, tenant_id);

CREATE INDEX IF NOT EXISTS idx_customer_satisfaction_agent_type
ON customer_satisfaction_feedback(agent_type, tenant_id);

CREATE INDEX IF NOT EXISTS idx_feedback_request_log_conversation
ON feedback_request_log(conversation_id, tenant_id);

CREATE INDEX IF NOT EXISTS idx_agent_feedback_loops_agent
ON agent_feedback_loops(agent_id, tenant_id, processing_status);

-- ============================================================================
-- 5. Create function to automatically request feedback on conversation end
-- ============================================================================
CREATE OR REPLACE FUNCTION request_conversation_feedback()
RETURNS TRIGGER AS $$
BEGIN
    -- Only request feedback when conversation becomes inactive (ends)
    IF OLD.is_active = true AND NEW.is_active = false THEN
        -- Check if feedback hasn't been requested yet
        IF NEW.feedback_requested_at IS NULL THEN
            -- Check if conversation had enough messages (at least 2 exchanges)
            IF NEW.message_count >= 4 THEN
                NEW.feedback_requested_at = NOW();
            END IF;
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION request_conversation_feedback() IS 'Automatically marks conversation for feedback request when it ends';

-- Drop trigger if exists and recreate
DROP TRIGGER IF EXISTS trigger_request_conversation_feedback ON chat_sessions;

CREATE TRIGGER trigger_request_conversation_feedback
    BEFORE UPDATE ON chat_sessions
    FOR EACH ROW
    EXECUTE FUNCTION request_conversation_feedback();

-- ============================================================================
-- 6. Create function to link customer satisfaction to conversations
-- ============================================================================
CREATE OR REPLACE FUNCTION link_satisfaction_to_conversation()
RETURNS TRIGGER AS $$
BEGIN
    -- Update chat_sessions when customer satisfaction feedback is submitted
    IF NEW.conversation_id IS NOT NULL THEN
        UPDATE chat_sessions
        SET
            feedback_submitted_at = NEW.created_at,
            conversation_rating = NEW.rating,
            conversation_feedback = NEW.comment
        WHERE id::text = NEW.conversation_id::text
        AND tenant_id = NEW.tenant_id;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION link_satisfaction_to_conversation() IS 'Links customer satisfaction feedback back to chat session';

-- Drop trigger if exists and recreate
DROP TRIGGER IF EXISTS trigger_link_satisfaction_to_conversation ON customer_satisfaction_feedback;

CREATE TRIGGER trigger_link_satisfaction_to_conversation
    AFTER INSERT ON customer_satisfaction_feedback
    FOR EACH ROW
    EXECUTE FUNCTION link_satisfaction_to_conversation();

-- ============================================================================
-- 7. Create function to check if feedback should be prompted
-- ============================================================================
CREATE OR REPLACE FUNCTION should_prompt_feedback(
    p_tenant_id VARCHAR(36),
    p_conversation_id VARCHAR(36)
)
RETURNS TABLE(
    should_prompt BOOLEAN,
    reason TEXT,
    conversation_message_count INTEGER,
    feedback_already_submitted BOOLEAN,
    feedback_already_requested BOOLEAN
) AS $$
DECLARE
    v_session RECORD;
    v_recent_requests INTEGER;
BEGIN
    -- Get conversation details
    SELECT
        cs.is_active,
        cs.message_count,
        cs.feedback_requested_at,
        cs.feedback_submitted_at
    INTO v_session
    FROM chat_sessions cs
    WHERE cs.id = p_conversation_id::uuid
    AND cs.tenant_id = p_tenant_id::uuid;

    -- Check if conversation exists
    IF NOT FOUND THEN
        RETURN QUERY SELECT
            false AS should_prompt,
            'Conversation not found' AS reason,
            0 AS conversation_message_count,
            false AS feedback_already_submitted,
            false AS feedback_already_requested;
        RETURN;
    END IF;

    -- Check if conversation is still active
    IF v_session.is_active THEN
        RETURN QUERY SELECT
            false AS should_prompt,
            'Conversation is still active' AS reason,
            v_session.message_count AS conversation_message_count,
            v_session.feedback_submitted_at IS NOT NULL AS feedback_already_submitted,
            v_session.feedback_requested_at IS NOT NULL AS feedback_already_requested;
        RETURN;
    END IF;

    -- Check if feedback already submitted
    IF v_session.feedback_submitted_at IS NOT NULL THEN
        RETURN QUERY SELECT
            false AS should_prompt,
            'Feedback already submitted' AS reason,
            v_session.message_count AS conversation_message_count,
            true AS feedback_already_submitted,
            v_session.feedback_requested_at IS NOT NULL AS feedback_already_requested;
        RETURN;
    END IF;

    -- Check if conversation had enough messages
    IF v_session.message_count < 4 THEN
        RETURN QUERY SELECT
            false AS should_prompt,
            'Conversation too short (minimum 4 messages required)' AS reason,
            v_session.message_count AS conversation_message_count,
            false AS feedback_already_submitted,
            v_session.feedback_requested_at IS NOT NULL AS feedback_already_requested;
        RETURN;
    END IF;

    -- Check if already requested too recently (prevent spam)
    SELECT COUNT(*)
    INTO v_recent_requests
    FROM feedback_request_log frl
    WHERE frl.conversation_id::text = p_conversation_id
    AND frl.tenant_id = p_tenant_id::uuid
    AND frl.requested_at > NOW() - INTERVAL '1 hour';

    IF v_recent_requests > 0 THEN
        RETURN QUERY SELECT
            false AS should_prompt,
            'Feedback already requested recently (within 1 hour)' AS reason,
            v_session.message_count AS conversation_message_count,
            false AS feedback_already_submitted,
            true AS feedback_already_requested;
        RETURN;
    END IF;

    -- All checks passed - should prompt for feedback
    RETURN QUERY SELECT
        true AS should_prompt,
        'Eligible for feedback collection' AS reason,
        v_session.message_count AS conversation_message_count,
        false AS feedback_already_submitted,
        v_session.feedback_requested_at IS NOT NULL AS feedback_already_requested;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION should_prompt_feedback IS 'Determines if feedback prompt should be shown to user';

-- ============================================================================
-- 8. Insert sample data for testing (optional - uncomment if needed)
-- ============================================================================
/*
-- This section can be uncommented for testing purposes
DO $$
DECLARE
    v_tenant_id UUID;
    v_session_id UUID;
BEGIN
    -- Get first tenant for testing
    SELECT id INTO v_tenant_id FROM tenants LIMIT 1;

    IF v_tenant_id IS NOT NULL THEN
        -- Create a test chat session
        INSERT INTO chat_sessions (
            id, tenant_id, session_name, session_type,
            is_active, message_count, created_at, updated_at
        ) VALUES (
            gen_random_uuid(), v_tenant_id, 'Test Feedback Session', 'analytics',
            false, 6, NOW() - INTERVAL '1 hour', NOW()
        ) RETURNING id INTO v_session_id;

        RAISE NOTICE 'Created test session: %', v_session_id;
    END IF;
END $$;
*/

-- ============================================================================
-- 9. Grant permissions (adjust as needed for your user/role setup)
-- ============================================================================
-- GRANT SELECT ON conversation_feedback_metrics TO your_app_user;
-- GRANT SELECT ON agent_performance_with_feedback TO your_app_user;

-- ============================================================================
-- Migration Complete
-- ============================================================================
SELECT
    'Walker Agent Feedback Enhancement Migration Completed' as status,
    NOW() as completed_at;

-- Verify the changes
SELECT
    'chat_sessions' as table_name,
    COUNT(*) FILTER (WHERE column_name = 'feedback_requested_at') as feedback_requested_at,
    COUNT(*) FILTER (WHERE column_name = 'feedback_submitted_at') as feedback_submitted_at,
    COUNT(*) FILTER (WHERE column_name = 'conversation_rating') as conversation_rating,
    COUNT(*) FILTER (WHERE column_name = 'conversation_feedback') as conversation_feedback
FROM information_schema.columns
WHERE table_name = 'chat_sessions'
AND column_name IN ('feedback_requested_at', 'feedback_submitted_at', 'conversation_rating', 'conversation_feedback');
