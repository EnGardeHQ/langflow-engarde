# Enhanced Web Scraping - Quick Reference

## Import

```python
from src.services.web_scraping import (
    EnhancedWebScrapingService,
    ScrapingConfig,
    ScrapedPage,
    CompetitorProfile,
    BacklinkData,
    ContentAnalysis,
)
```

## Quick Start

```python
# Initialize with defaults
scraper = EnhancedWebScrapingService()

# Or with custom config
config = ScrapingConfig(
    max_concurrent=10,
    throttle_delay=0.5,
    enable_nlp=True
)
scraper = EnhancedWebScrapingService(config=config)

# Use with context manager (recommended)
async with EnhancedWebScrapingService(config) as scraper:
    page = await scraper.scrape_with_javascript("https://example.com")
```

## Common Operations

### 1. Scrape Single Page with JavaScript

```python
page = await scraper.scrape_with_javascript(
    url="https://example.com",
    wait_for_selector=".content",  # Optional
    wait_for_timeout=5000           # Optional
)

print(f"Title: {page.title}")
print(f"Status: {page.status_code}")
print(f"Links: {len(page.links)}")
print(f"Error: {page.error}")
```

### 2. Batch Scrape Multiple URLs

```python
urls = ["https://example.com/page1", "https://example.com/page2"]

results = await scraper.batch_scrape(
    urls,
    max_concurrent=5,
    use_javascript=False  # Lightweight scraping
)

for page in results:
    if not page.error:
        print(f"✓ {page.url}: {page.title}")
```

### 3. Scrape Competitor Profile

```python
profile = await scraper.scrape_competitor_profile(
    domain="competitor.com",
    max_blog_posts=5
)

print(f"Homepage: {profile.homepage_data.title}")
print(f"Blog posts: {len(profile.blog_posts)}")
print(f"Social: {profile.social_links}")
print(f"Tech: {profile.technologies}")
```

### 4. Analyze Content Themes

```python
analyses = await scraper.analyze_content_themes([
    "https://competitor.com",
    "https://competitor.com/blog/post1",
])

for analysis in analyses:
    print(f"URL: {analysis.url}")
    print(f"Sentiment: {analysis.sentiment_polarity:.2f}")
    print(f"Readability: {analysis.readability_score:.1f}")
    print(f"Topics: {analysis.topics[:3]}")
```

### 5. Discover Backlinks

```python
backlinks = await scraper.discover_backlinks(
    domain="example.com",
    limit=100
)

for backlink in backlinks:
    print(f"{backlink.referring_domain} → {backlink.target_domain}")
    print(f"  Anchor: {backlink.anchor_text}")
```

## Configuration Cheat Sheet

### Environment Variables

```bash
# Essential
SCRAPER_MAX_CONCURRENT=5
SCRAPER_THROTTLE_DELAY=1.0
SCRAPER_RESPECT_ROBOTS=true

# JavaScript
SCRAPER_USE_PLAYWRIGHT=false
SCRAPER_PLAYWRIGHT_TIMEOUT=30000

# Circuit Breaker
SCRAPER_FAILURE_THRESHOLD=5
SCRAPER_RECOVERY_TIMEOUT=60

# Content Analysis
SCRAPER_ENABLE_NLP=true
SCRAPER_MAX_TOPICS=10
```

### Programmatic Config

```python
config = ScrapingConfig(
    default_timeout=30,
    max_retries=3,
    throttle_delay=1.0,
    max_concurrent=5,
    enable_nlp=True,
    failure_threshold=5,
)
```

## Error Handling

```python
from src.services.web_scraping import (
    CircuitBreakerError,
    RobotsDisallowedError,
    ScrapingError,
)

try:
    page = await scraper.scrape_with_javascript(url)
except CircuitBreakerError:
    print("Domain is experiencing issues, circuit is open")
except RobotsDisallowedError:
    print("Robots.txt disallows scraping this URL")
except ScrapingError as e:
    print(f"Scraping failed: {e}")

# Or check page.error
if page.error:
    print(f"Failed: {page.error}")
```

## Integration with SEO Agent

```python
from src.agents.seo_content_walker import SEOContentWalkerAgent

agent = SEOContentWalkerAgent(db=db_session, cache=cache)

# Scrape competitor profiles
profiles = await agent.scrape_competitor_profiles(
    competitor_domains=["competitor1.com", "competitor2.com"],
    max_blog_posts=5
)

# Analyze content
analyses = await agent.analyze_competitor_content(
    competitor_domains=["competitor1.com"]
)

# Discover backlinks
backlinks = await agent.discover_competitor_backlinks(
    competitor_domains=["competitor1.com"],
    limit_per_domain=50
)
```

## Data Structures

### ScrapedPage
```python
page.url                 # str
page.html                # str (full HTML)
page.text                # str (cleaned text)
page.title               # str
page.meta_description    # str
page.meta_keywords       # str
page.headings            # Dict[str, List[str]]
page.links               # List[str]
page.images              # List[str]
page.status_code         # int
page.response_time_ms    # float
page.error               # Optional[str]
page.is_javascript_rendered  # bool
```

### CompetitorProfile
```python
profile.domain           # str
profile.homepage_data    # ScrapedPage
profile.about_page_data  # Optional[ScrapedPage]
profile.blog_posts       # List[ScrapedPage]
profile.contact_info     # Dict[str, str]
profile.social_links     # Dict[str, str]
profile.technologies     # List[str]
profile.error            # Optional[str]
```

### ContentAnalysis
```python
analysis.url                    # str
analysis.topics                 # List[Dict[str, float]]
analysis.sentiment_polarity     # float (-1 to 1)
analysis.sentiment_subjectivity # float (0 to 1)
analysis.readability_score      # float (0 to 100)
analysis.word_count             # int
analysis.sentence_count         # int
analysis.avg_words_per_sentence # float
analysis.heading_structure      # Dict[str, int]
analysis.keyword_density        # Dict[str, float]
```

## Performance Tips

1. **Use lightweight scraping for static content:**
   ```python
   results = await scraper.batch_scrape(urls, use_javascript=False)
   ```

2. **Adjust concurrency based on target:**
   ```python
   # For robust servers
   config = ScrapingConfig(max_concurrent=10)

   # For slower servers
   config = ScrapingConfig(max_concurrent=3, throttle_delay=2.0)
   ```

3. **Use context manager for cleanup:**
   ```python
   async with EnhancedWebScrapingService(config) as scraper:
       # Resources automatically cleaned up
       pass
   ```

4. **Disable features you don't need:**
   ```python
   config = ScrapingConfig(
       enable_nlp=False,           # Skip NLP analysis
       respect_robots_txt=False,   # Skip robots.txt check (use carefully!)
   )
   ```

## Common Patterns

### Pattern 1: Analyze Multiple Competitors

```python
async def analyze_competitors(competitor_domains):
    async with EnhancedWebScrapingService() as scraper:
        # Scrape profiles
        profiles = {}
        for domain in competitor_domains:
            profiles[domain] = await scraper.scrape_competitor_profile(domain)

        # Batch analyze content
        all_urls = []
        for profile in profiles.values():
            if profile.homepage_data:
                all_urls.append(profile.homepage_data.url)
            all_urls.extend([p.url for p in profile.blog_posts])

        analyses = await scraper.analyze_content_themes(all_urls)

        return profiles, analyses
```

### Pattern 2: Monitor Competitor Changes

```python
async def check_for_changes(domain):
    async with EnhancedWebScrapingService() as scraper:
        current = await scraper.scrape_with_javascript(f"https://{domain}")

        # Compare with previous version (from database)
        if current.html != previous.html:
            # Content changed
            analysis = await scraper.analyze_content_themes([current.url])
            return {"changed": True, "analysis": analysis[0]}

        return {"changed": False}
```

### Pattern 3: Discover Link Opportunities

```python
async def find_link_opportunities(my_domain, competitor_domains):
    async with EnhancedWebScrapingService() as scraper:
        opportunities = []

        for domain in competitor_domains:
            backlinks = await scraper.discover_backlinks(domain, limit=50)

            # Find backlinks we don't have
            for backlink in backlinks:
                # Check if we're on referring domain
                our_page = await scraper.scrape_with_javascript(backlink.referring_url)
                if my_domain not in our_page.text:
                    opportunities.append({
                        "referring_domain": backlink.referring_domain,
                        "url": backlink.referring_url,
                        "competitor": domain,
                    })

        return opportunities
```

## Testing

```bash
# Run all tests
pytest tests/services/test_enhanced_web_scraper.py -v

# Run specific test
pytest tests/services/test_enhanced_web_scraper.py::TestBatchScraping -v

# With coverage
pytest tests/services/test_enhanced_web_scraper.py --cov=src.services.web_scraping
```

## File Locations

- **Service:** `/Users/cope/EnGardeHQ/Onside/src/services/web_scraping/enhanced_scraper.py`
- **Config:** `/Users/cope/EnGardeHQ/Onside/src/config/scraping_config.py`
- **Tests:** `/Users/cope/EnGardeHQ/Onside/tests/services/test_enhanced_web_scraper.py`
- **Docs:** `/Users/cope/EnGardeHQ/Onside/src/services/web_scraping/README.md`

## Need Help?

1. Check the README: `src/services/web_scraping/README.md`
2. Review tests for examples: `tests/services/test_enhanced_web_scraper.py`
3. See integration in: `src/agents/seo_content_walker.py`
4. Check configuration: `src/config/scraping_config.py`
