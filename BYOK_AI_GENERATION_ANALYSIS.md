# BYOK (Bring Your Own Key) & AI Content Generation Analysis

**Date:** 2026-01-25
**Status:** Implementation Analysis Complete
**Version:** 1.0

---

## Executive Summary

The BYOK feature for LLM APIs is **FULLY IMPLEMENTED** with a robust architecture. The AI content generation capabilities are **PARTIALLY IMPLEMENTED** - the infrastructure is complete, but the frontend endpoint `/content/generate` returns mock data and needs to be connected to the brand-aware content generator.

### Key Findings:

✅ **BYOK Implementation: COMPLETE**
- Tenant-specific LLM key storage with encryption
- Multi-provider support (OpenAI, Anthropic, Google, DeepSeek, Qwen)
- API endpoints for key management
- Proper fallback to platform default keys

⚠️ **AI Content Generation: NEEDS INTEGRATION**
- Brand-aware content generator exists and is fully functional
- Simple `/content/generate` endpoint exists but returns mock data
- Needs to be wired to `BrandContentGenerator` service
- Frontend component ready and functional

❌ **Default LLAMA Platform Key: NOT CONFIGURED**
- No default LLAMA key found in configuration
- Platform uses OpenAI and Anthropic as default providers
- LLAMA/Meta can be added as tenant BYOK key or platform default

---

## 1. BYOK Implementation Details

### 1.1 Database Schema

**Table:** `tenant_llm_keys`

```sql
CREATE TABLE tenant_llm_keys (
    id VARCHAR(36) PRIMARY KEY,
    tenant_id VARCHAR(36) NOT NULL,
    provider VARCHAR(50) NOT NULL,
    api_key_encrypted VARCHAR NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE,
    FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE
);

CREATE INDEX ix_tenant_llm_keys_tenant_id ON tenant_llm_keys(tenant_id);
```

**Migration:** `/Users/cope/EnGardeHQ/production-backend/alembic/versions/20251123_add_llm_keys.py`

### 1.2 Supported Providers

Located in: `/Users/cope/EnGardeHQ/production-backend/app/models/llm_models.py`

```python
class LLMProvider(str, enum.Enum):
    OPENAI = "openai"
    ANTHROPIC = "anthropic"
    GOOGLE = "google"
    DEEPSEEK = "deepseek"
    QWEN = "qwen"
```

### 1.3 API Endpoints

**Base Path:** `/api/llm-keys`

#### List Configured Providers
```
GET /api/llm-keys
Response: { "providers": ["openai", "anthropic"] }
```

#### Save/Update LLM Key
```
POST /api/llm-keys
Body: {
  "provider": "openai",
  "api_key": "sk-..."
}
Response: { "message": "Key for openai saved successfully" }
```

#### Delete LLM Key
```
DELETE /api/llm-keys/{provider}
Response: { "message": "Key for openai deleted successfully" }
```

**Router:** `/Users/cope/EnGardeHQ/production-backend/app/routers/llm_keys.py`

### 1.4 Key Management Service

**Service:** `/Users/cope/EnGardeHQ/production-backend/app/services/llm_key_service.py`

**Key Features:**
- Encryption/decryption of API keys using `encryption_service`
- Secure storage with tenant isolation
- Active/inactive key management
- Provider-specific key lookup

**Key Methods:**
```python
def get_decrypted_key(tenant_id: str, provider: str) -> Optional[str]
def save_key(tenant_id: str, provider: str, api_key: str) -> TenantLLMKey
def delete_key(tenant_id: str, provider: str) -> bool
def list_configured_providers(tenant_id: str) -> List[str]
```

### 1.5 Encryption Service

**Service:** `/Users/cope/EnGardeHQ/production-backend/app/services/encryption_service.py` (referenced)

Uses Fernet encryption with tenant-specific salt for secure key storage.

---

## 2. AI Service Integration

### 2.1 AI Service Manager

**Service:** `/Users/cope/EnGardeHQ/production-backend/app/services/ai_service_wrapper.py`

**Architecture:**
```
AIServiceManager (Singleton)
├── Global Services (Platform Default Keys)
│   ├── OpenAI Service
│   └── Anthropic Service
└── Tenant Services (BYOK Keys)
    └── {tenant_id}
        ├── OpenAI Service (tenant key)
        └── Anthropic Service (tenant key)
```

**Key Selection Logic:**
```python
def get_service(provider: AIProvider, model_type: ModelType, tenant_id: str):
    # 1. Check tenant-specific key cache
    if tenant_id in tenant_services:
        return tenant_services[tenant_id][provider]

    # 2. Try to fetch tenant key from database
    tenant_key = llm_key_service.get_decrypted_key(tenant_id, provider)
    if tenant_key:
        # Create service with tenant key
        service = create_service_instance(provider, tenant_key)
        cache_service(tenant_id, provider, service)
        return service

    # 3. Fallback to global platform service
    return services[provider]
```

### 2.2 Supported Providers

**OpenAI Service:**
- Models: `gpt-4o`, `gpt-4-turbo`, `gpt-3.5-turbo`, `text-embedding-3-large`
- Default model: `gpt-4o` for content generation
- Cost tracking and rate limiting

**Anthropic Service:**
- Models: `claude-3-5-sonnet-20241022`, `claude-3-haiku-20240307`, `claude-3-opus-20240229`
- Default model: `claude-3-5-sonnet-20241022`
- Cost tracking and rate limiting

### 2.3 Default Provider Configuration

Located in: `/Users/cope/EnGardeHQ/production-backend/app/services/ai_service_wrapper.py`

```python
self.default_providers = {
    ModelType.COPY_GENERATION: AIProvider.OPENAI,
    ModelType.CULTURAL_ANALYSIS: AIProvider.ANTHROPIC,
    ModelType.IMAGE_ANALYSIS: AIProvider.OPENAI,
    ModelType.EMBEDDINGS: AIProvider.OPENAI,
    ModelType.REASONING: AIProvider.ANTHROPIC
}
```

**Platform Default Keys** (from environment):
- `OPENAI_API_KEY` - Platform default OpenAI key
- `ANTHROPIC_API_KEY` - Platform default Anthropic key
- `GOOGLE_API_KEY` - Platform default Google key

**Configuration File:** `/Users/cope/EnGardeHQ/production-backend/app/core/config.py`

---

## 3. AI Content Generation Flow

### 3.1 Complete Data Flow

```
Frontend (AIContentGenerator.tsx)
    ↓
    POST /api/content/generate
    {
      prompt: "...",
      platforms: ["meta"],
      tone: "professional",
      length: "medium",
      keywords: ["keyword1"],
      target_audience: "..."
    }
    ↓
Router (content.py)
    ↓
    generate_content_ai() [CURRENTLY RETURNS MOCK DATA]
    ⚠️ SHOULD CALL ↓
    ↓
BrandContentGenerator Service
    ↓
    1. Fetch brand style guide
    2. Build brand-aware prompt
    3. For each variant:
       ↓
       AIServiceManager.generate_text()
       ↓
       Check tenant key → Fallback to platform key
       ↓
       OpenAI/Anthropic API
       ↓
    4. Parse generated content
    5. Validate brand adherence
    6. Return variants with compliance report
    ↓
Response
    {
      success: true,
      variants: [{...}],
      compliance_report: {...},
      brand_guide_available: true
    }
```

### 3.2 Current Implementation Status

#### ✅ Fully Implemented Components:

1. **Frontend Component** (`/Users/cope/EnGardeHQ/production-frontend/components/content/AIContentGenerator.tsx`)
   - Complete UI for content generation
   - Supports platforms, tone, length, keywords
   - Displays generated variations
   - Copy and use content functionality

2. **Brand Content Generator** (`/Users/cope/EnGardeHQ/production-backend/app/services/brand_content_generator.py`)
   - Brand-aware content generation
   - Adherence level enforcement (STRICT, MODERATE, LOOSE, CUSTOM)
   - Multi-variant generation
   - Brand compliance validation
   - Complete prompt engineering with brand context

3. **AI Service Wrapper** (`/Users/cope/EnGardeHQ/production-backend/app/services/ai_service_wrapper.py`)
   - Provider abstraction (OpenAI, Anthropic)
   - Tenant key integration
   - Usage tracking and cost monitoring
   - Rate limiting and reliability features

4. **LLM Key Management**
   - Complete CRUD operations
   - Encryption/decryption
   - Multi-tenant isolation

#### ⚠️ Needs Integration:

**Content Generation Endpoint** (`/Users/cope/EnGardeHQ/production-backend/app/routers/content.py`)

**Current implementation (lines 619-651):**
```python
@router.post("/generate")
async def generate_content_ai(
    prompt: str,
    content_type: str,
    additional_params: Optional[dict] = None
):
    # Returns MOCK DATA
    return {
        "title": f"AI Generated {content_type.title()}",
        "content_body": f"This is AI-generated...",
        "suggestions": [...],
        "metadata": {...}
    }
```

**What it should do:**
```python
@router.post("/generate")
async def generate_content_ai(
    request: AIGenerationRequest,  # Use proper schema
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    # Get brand and tenant context
    brand_id = get_current_brand_id(db, current_user)
    tenant_id = get_tenant_id_from_current_brand(db, current_user)

    # Use BrandContentGenerator
    generator = get_brand_content_generator(db)
    response = await generator.generate_content(
        request=request,
        brand_id=brand_id,
        tenant_id=tenant_id,
        user_id=current_user.id
    )

    return response
```

**Alternate endpoint exists:** `/api/content/generate-with-brand` (lines 654-755)
- This endpoint IS properly integrated with BrandContentGenerator
- Frontend should use this endpoint instead

---

## 4. Missing Components

### 4.1 Default LLAMA Configuration

**Status:** ❌ NOT CONFIGURED

**Current default providers:**
- OpenAI (for content generation, embeddings, image analysis)
- Anthropic (for cultural analysis, reasoning)

**To add LLAMA as platform default:**

1. **Add LLAMA provider to enum:**
```python
# app/models/llm_models.py
class LLMProvider(str, enum.Enum):
    OPENAI = "openai"
    ANTHROPIC = "anthropic"
    GOOGLE = "google"
    DEEPSEEK = "deepseek"
    QWEN = "qwen"
    META_LLAMA = "meta_llama"  # ADD THIS
```

2. **Create LLAMA service wrapper:**
```python
# app/services/ai_service_wrapper.py
class MetaLlamaService(BaseAIService):
    def __init__(self, api_key: str, usage_tracker=None):
        super().__init__(api_key, usage_tracker)
        self.provider = AIProvider.META_LLAMA
        self.client = # Initialize Meta LLAMA client

        self.models = {
            ModelType.COPY_GENERATION: "llama-3-70b",
            ModelType.REASONING: "llama-3-70b"
        }
```

3. **Add to environment configuration:**
```bash
# .env
META_LLAMA_API_KEY=your-meta-llama-key
```

4. **Initialize in AIServiceManager:**
```python
# app/services/ai_service_wrapper.py
# In _load_env_config()
meta_llama_key = os.getenv("META_LLAMA_API_KEY")
if meta_llama_key:
    self.providers["meta_llama"] = ProviderConfig(
        provider_type="meta_llama",
        api_key=meta_llama_key,
        # ... config
    )
```

**OR use as tenant BYOK:**
- Users can add their own Meta LLAMA keys via `/api/llm-keys` endpoint
- No platform default needed

---

## 5. Testing Recommendations

### 5.1 Test File Created

**Location:** `/Users/cope/EnGardeHQ/production-backend/tests/test_byok_ai_generation.py`

**Test Coverage:**
1. ✅ LLM key management (CRUD operations)
2. ✅ Tenant key encryption/decryption
3. ✅ AI service integration with tenant keys
4. ✅ Fallback to platform default keys
5. ✅ Content generation with tenant keys
6. ✅ Platform default provider configuration

**Run tests:**
```bash
cd /Users/cope/EnGardeHQ/production-backend
pytest tests/test_byok_ai_generation.py -v -s
```

### 5.2 Manual Testing Steps

#### Test BYOK Key Management:

1. **Add a tenant LLM key:**
```bash
curl -X POST http://localhost:8000/api/llm-keys \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "provider": "openai",
    "api_key": "sk-your-openai-key"
  }'
```

2. **List configured providers:**
```bash
curl http://localhost:8000/api/llm-keys \
  -H "Authorization: Bearer $TOKEN"
```

3. **Delete a key:**
```bash
curl -X DELETE http://localhost:8000/api/llm-keys/openai \
  -H "Authorization: Bearer $TOKEN"
```

#### Test AI Content Generation:

1. **Using brand-aware endpoint (WORKING):**
```bash
curl -X POST http://localhost:8000/api/content/generate-with-brand \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "prompt": "Write a social media post about sustainability",
    "content_type": "social_media",
    "adherence_level": "MODERATE",
    "target_platform": "meta",
    "variants": 2
  }'
```

2. **Using simple endpoint (RETURNS MOCK - NEEDS INTEGRATION):**
```bash
curl -X POST "http://localhost:8000/api/content/generate?prompt=test&content_type=social_media" \
  -H "Authorization: Bearer $TOKEN"
```

#### Test Frontend Component:

1. Navigate to Content Studio in the application
2. Click "AI Generate" button
3. Enter prompt and select options
4. Verify generated content appears
5. Check browser network tab for API calls

---

## 6. Code Locations Reference

### Backend Files:

| Component | File Path |
|-----------|-----------|
| LLM Models | `/Users/cope/EnGardeHQ/production-backend/app/models/llm_models.py` |
| LLM Key Service | `/Users/cope/EnGardeHQ/production-backend/app/services/llm_key_service.py` |
| LLM Keys Router | `/Users/cope/EnGardeHQ/production-backend/app/routers/llm_keys.py` |
| AI Service Wrapper | `/Users/cope/EnGardeHQ/production-backend/app/services/ai_service_wrapper.py` |
| Brand Content Generator | `/Users/cope/EnGardeHQ/production-backend/app/services/brand_content_generator.py` |
| Content Router | `/Users/cope/EnGardeHQ/production-backend/app/routers/content.py` |
| Config | `/Users/cope/EnGardeHQ/production-backend/app/core/config.py` |
| AI Config | `/Users/cope/EnGardeHQ/production-backend/app/services/ai_config.py` |
| Migration | `/Users/cope/EnGardeHQ/production-backend/alembic/versions/20251123_add_llm_keys.py` |
| Test File | `/Users/cope/EnGardeHQ/production-backend/tests/test_byok_ai_generation.py` |

### Frontend Files:

| Component | File Path |
|-----------|-----------|
| AI Content Generator UI | `/Users/cope/EnGardeHQ/production-frontend/components/content/AIContentGenerator.tsx` |
| Content API Hooks | `/Users/cope/EnGardeHQ/production-frontend/lib/api/content.ts` |

---

## 7. Recommendations

### 7.1 Immediate Actions (High Priority)

1. **Fix Content Generation Endpoint Integration**
   - Update `/api/content/generate` to use `BrandContentGenerator`
   - OR update frontend to use `/api/content/generate-with-brand` endpoint
   - Ensure proper request/response schema mapping

2. **Configure Platform Default LLM Key**
   - Add `OPENAI_API_KEY` or `ANTHROPIC_API_KEY` to environment variables
   - Initialize `ai_service_manager` with platform keys on startup
   - Document which provider is the platform default

3. **Add End-to-End Tests**
   - Test complete flow from frontend → backend → LLM API
   - Test tenant key usage vs platform key fallback
   - Test error handling when keys are invalid

### 7.2 Future Enhancements (Medium Priority)

1. **Add Meta LLAMA Support**
   - Create `MetaLlamaService` class
   - Add to provider enum
   - Configure as platform default or BYOK option

2. **Key Rotation & Security**
   - Add key expiration dates
   - Implement automatic key rotation reminders
   - Add key usage analytics per tenant

3. **Cost Management**
   - Add per-tenant usage limits
   - Track costs by tenant and provider
   - Alert when approaching budget limits

4. **UI Improvements**
   - Add LLM key management UI in tenant settings
   - Show which provider is being used for generation
   - Display usage statistics and costs

### 7.3 Documentation Updates (Low Priority)

1. **API Documentation**
   - Add OpenAPI/Swagger docs for BYOK endpoints
   - Document authentication requirements
   - Add example requests/responses

2. **User Guide**
   - How to add custom LLM keys
   - Which providers are supported
   - Pricing and usage tracking

---

## 8. Summary

### ✅ What Works:

1. **BYOK Infrastructure** - Complete and production-ready
   - Tenant key storage with encryption
   - Multi-provider support
   - API endpoints for key management
   - Proper fallback logic

2. **AI Service Layer** - Robust and well-architected
   - Provider abstraction
   - Tenant key integration
   - Cost tracking and rate limiting
   - Usage monitoring

3. **Brand Content Generator** - Fully functional
   - Brand-aware content generation
   - Adherence level enforcement
   - Multi-variant generation
   - Compliance validation

4. **Frontend Component** - Complete and functional
   - UI for content generation
   - Proper request formatting
   - Results display and management

### ⚠️ What Needs Work:

1. **Endpoint Integration** - Simple fix
   - `/api/content/generate` returns mock data
   - Should call `BrandContentGenerator` service
   - OR redirect frontend to use `/api/content/generate-with-brand`

2. **Platform Default Keys** - Configuration needed
   - Add `OPENAI_API_KEY` or `ANTHROPIC_API_KEY` to environment
   - Initialize on startup
   - Document platform default provider

3. **Testing** - Add integration tests
   - End-to-end content generation
   - Tenant key vs platform key usage
   - Error handling

### ❌ What's Missing:

1. **LLAMA Platform Default** - Not configured
   - No Meta LLAMA provider implementation
   - Can be added as BYOK or platform default
   - Requires service wrapper implementation

---

## 9. Next Steps

**Immediate (Week 1):**
1. Fix `/api/content/generate` endpoint integration
2. Configure platform default LLM key
3. Run manual tests with real API keys

**Short-term (Week 2-3):**
1. Add comprehensive integration tests
2. Document BYOK setup for users
3. Add error handling improvements

**Long-term (Month 2-3):**
1. Implement Meta LLAMA support (if needed)
2. Add usage analytics and cost tracking UI
3. Implement key rotation features

---

**Analysis completed by:** Claude Code
**Report generated:** 2026-01-25
**Review status:** Ready for implementation
