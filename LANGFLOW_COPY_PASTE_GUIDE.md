# Langflow Python Function - Copy-Paste Guide

**Exact instructions for pasting agent code into Langflow UI**

---

## 🎯 What to Copy and Where to Paste

When you open the Python Function component in Langflow, you'll see this template code:

```python
from langflow.custom import Component
from langflow.custom.utils import get_function
from langflow.io import CodeInput, Output
from langflow.schema import Data, dotdict
from langflow.schema.message import Message


class PythonFunctionComponent(Component):
    display_name = "Python Function"
    description = "Define and execute a Python function that returns a Data object or a Message."
    icon = "Python"
    name = "PythonFunction"
    beta = True

    inputs = [
        CodeInput(
            name="function_code",
            display_name="Function Code",
            info="The code for the function.",
        ),
    ]

    outputs = [
        Output(
            name="function_output",
            display_name="Function Callable",
            method="get_function_callable",
        ),
        Output(
            name="function_output_data",
            display_name="Function Output (Data)",
            method="execute_function_data",
        ),
        Output(
            name="function_output_str",
            display_name="Function Output (Message)",
            method="execute_function_message",
        ),
    ]

    def get_function_callable(self) -> Callable:
        function_code = self.function_code
        self.status = function_code
        func = get_function(function_code)
        return func

    def execute_function(self) -> List[dotdict | str] | dotdict | str:
        function_code = self.function_code

        if not function_code:
            return "No function code provided."

        try:
            func = get_function(function_code)
            return func()
        except Exception as e:
            return f"Error executing function: {str(e)}"

    def execute_function_data(self) -> List[Data]:
        results = self.execute_function()
        results = results if isinstance(results, list) else [results]
        data = [(Data(text=x) if isinstance(x, str) else Data(**x)) for x in results]
        return data

    def execute_function_message(self) -> Message:
        results = self.execute_function()
        results = results if isinstance(results, list) else [results]
        results_list = [str(x) for x in results]
        results_str = "\n".join(results_list)
        data = Message(text=results_str)
        return data
```

---

## ✂️ What to Do: Step-by-Step

### Step 1: Locate the "Function Code" Field

In the Langflow Python Function node editor, you'll see a field labeled **"Function Code"**. This is where you paste the agent code.

**Look for:**
- A text area with the label "Function Code"
- It's inside the `CodeInput` section
- It may have placeholder text or be empty

### Step 2: Copy ONLY the Function Definition

From the agent files (`FINAL_WALKER_AGENTS_COMPLETE.md` or `FINAL_ENGARDE_AGENTS_COMPLETE.md`), copy **ONLY** the function definition starting with `def run(...):`

**✅ CORRECT - Copy This:**

```python
def run(tenant_id: str) -> dict:
    """
    SEO Walker Agent - COMPLETE
    Data Sources:
      1. Onside microservice (SEO-specific data)
      2. BigQuery (historical SEO trends)
      3. ZeroDB (real-time crawl events)
      4. PostgreSQL (store suggestions via API)
    """
    import os
    import httpx
    import json
    from datetime import datetime, timedelta
    from google.cloud import bigquery
    from google.oauth2 import service_account

    # ... rest of the function ...

    return {
        "success": True,
        "tenant_id": tenant_id,
        # ... rest of return statement
    }
```

**❌ INCORRECT - Do NOT Copy:**

- Do NOT copy the entire PythonFunctionComponent class
- Do NOT copy the import statements at the top of the file (the Component class imports)
- Do NOT copy the markdown formatting (```python blocks)

### Step 3: Paste Into "Function Code" Field

1. Click into the "Function Code" text area
2. **Select all existing text** (Cmd+A on Mac, Ctrl+A on Windows)
3. **Paste your copied function** (Cmd+V on Mac, Ctrl+V on Windows)
4. The text area should now contain ONLY your `def run(...)` function

### Step 4: Click "Check & Save"

After pasting, click the "Check & Save" button to validate the code.

---

## 📋 Visual Guide

```
┌─────────────────────────────────────────────────────────────┐
│ Python Function Component                                   │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│ Function Code: ┌──────────────────────────────────────────┐ │
│                │ def run(tenant_id: str) -> dict:         │ │
│                │     """                                  │ │
│                │     SEO Walker Agent                     │ │
│                │     """                                  │ │
│                │     import os                            │ │
│                │     import httpx                         │ │
│    PASTE       │     # ... your agent code here ...       │ │
│    HERE ───────▶     return {                             │ │
│                │         "success": True,                 │ │
│                │         # ...                            │ │
│                │     }                                    │ │
│                └──────────────────────────────────────────┘ │
│                                                              │
│ [Check & Save]                                               │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

---

## 🔍 What the Function Code Field Expects

The "Function Code" field expects a **single Python function** that:

1. **Starts with** `def function_name(...):` (e.g., `def run(tenant_id: str):`)
2. **Contains** all necessary imports inside the function body
3. **Returns** a value (dict, str, list, or Data object)

**Example of correct format:**

```python
def run(tenant_id: str) -> dict:
    import os
    import httpx

    # Your logic here
    result = {"success": True, "data": "..."}

    return result
```

---

## ⚠️ Common Mistakes to Avoid

### ❌ Mistake 1: Pasting the Entire Component Class

```python
# DO NOT PASTE THIS:
class PythonFunctionComponent(Component):
    def execute_function(self):
        # ...
```

**Why:** The Component class is already provided by Langflow. You only need the function definition.

### ❌ Mistake 2: Pasting with Markdown Code Blocks

```python
# DO NOT PASTE THIS:
```python
def run(tenant_id: str) -> dict:
    # ...
```
# (Do not include the ```python markers)
```

**Why:** The markdown code block syntax is not valid Python.

### ❌ Mistake 3: Not Including Return Statement

```python
# DO NOT PASTE THIS:
def run(tenant_id: str) -> dict:
    import os
    result = {"success": True}
    # Missing return statement!
```

**Why:** The function must return a value.

### ✅ Correct Format

```python
# PASTE EXACTLY THIS FORMAT:
def run(tenant_id: str) -> dict:
    import os
    import httpx

    result = {"success": True, "tenant_id": tenant_id}
    return result  # ✅ Has return statement
```

---

## 🎯 Quick Reference: What to Copy From Each File

### From FINAL_WALKER_AGENTS_COMPLETE.md

**Agent 1: SEO Walker**
- Start copying at: `def run(tenant_id: str) -> dict:`
- Stop copying at: `}` (the closing brace of the return statement)

**Agent 2: Paid Ads Walker**
- Start copying at: `def run(tenant_id: str) -> dict:`
- Stop copying at: `}` (the closing brace of the return statement)

**Agent 3: Content Walker**
- Start copying at: `def run(tenant_id: str) -> dict:`
- Stop copying at: `}` (the closing brace of the return statement)

**Agent 4: Audience Intelligence Walker**
- Start copying at: `def run(tenant_id: str) -> dict:`
- Stop copying at: `}` (the closing brace of the return statement)

### From FINAL_ENGARDE_AGENTS_COMPLETE.md

**Agent 5-10: Same pattern**
- Start copying at: `def run(...) -> dict:` (parameters vary)
- Stop copying at: `}` (the closing brace of the return statement)

---

## 📝 Example: Complete Copy-Paste Workflow

### 1. Open Agent File
Open `FINAL_WALKER_AGENTS_COMPLETE.md`

### 2. Find Agent Section
Scroll to "## Agent 1: SEO Walker"

### 3. Copy Function
Select from `def run(tenant_id: str) -> dict:` to the final `}`

### 4. Open Langflow
Navigate to your flow, click Python Function node

### 5. Paste Code
Click "Function Code" field, select all, paste

### 6. Verify
Code should look like:
```python
def run(tenant_id: str) -> dict:
    """
    SEO Walker Agent - COMPLETE
    ...
    """
    import os
    ...
    return {
        "success": True,
        ...
    }
```

### 7. Save
Click "Check & Save"

---

## ✅ Verification Checklist

After pasting, verify:

- [ ] Function starts with `def run(...)`
- [ ] Function has a docstring (optional but helpful)
- [ ] All imports are inside the function body
- [ ] Function has a `return` statement at the end
- [ ] No markdown code block markers (```python)
- [ ] No Component class definition
- [ ] "Check & Save" button shows success (green checkmark)

---

## 🔧 If "Check & Save" Fails

**Common errors and fixes:**

**Error: "SyntaxError: invalid syntax"**
- Check for missing colons, parentheses, or brackets
- Ensure proper indentation (use spaces, not tabs)

**Error: "NameError: name 'X' is not defined"**
- Make sure all imports are inside the function
- Check for typos in variable names

**Error: "IndentationError: expected an indented block"**
- Ensure consistent indentation (4 spaces per level)
- Verify no mixing of tabs and spaces

**Error: "Function must return a value"**
- Add `return` statement at the end of your function
- Ensure return statement is not inside a try/except block without fallback

---

## 🎨 Syntax Highlighting

The Langflow editor provides syntax highlighting. Your code should appear with:

- **Blue** for keywords (def, import, return, if, for, etc.)
- **Green** for strings ("tenant_id", "success", etc.)
- **Purple** for built-in functions (len, sum, str, etc.)
- **Orange** for numbers (0, 100, 0.85, etc.)

If colors don't appear, the code may have syntax errors.

---

## 📱 Remove DataStax Logo (Langflow UI Customization)

**The DataStax logo appears in the lower-left corner of Langflow UI**

### Option 1: CSS Override (Temporary, Browser-Only)

1. **Open Browser Developer Tools:**
   - Chrome/Edge: Press `F12` or `Cmd+Option+I` (Mac) / `Ctrl+Shift+I` (Windows)
   - Firefox: Press `F12` or `Cmd+Option+K` (Mac) / `Ctrl+Shift+K` (Windows)

2. **Open Console Tab**

3. **Paste This Code:**

```javascript
// Hide DataStax logo
const style = document.createElement('style');
style.textContent = `
  /* Hide DataStax/Langflow logo in footer */
  .langflow-logo,
  [class*="langflow-logo"],
  [class*="datastax"],
  footer img,
  footer svg,
  footer a[href*="datastax"],
  footer a[href*="langflow"] {
    display: none !important;
  }

  /* Optional: Hide entire footer */
  footer {
    display: none !important;
  }
`;
document.head.appendChild(style);
```

4. **Press Enter**

The logo should disappear. This is **temporary** and will reset when you refresh the page.

---

### Option 2: Custom Docker Image (Permanent)

To permanently remove the logo, you need to modify the Langflow frontend and rebuild:

**1. Clone Langflow Repository:**

```bash
git clone https://github.com/logspace-ai/langflow.git
cd langflow
```

**2. Locate Logo Component:**

```bash
# Find logo component files
find . -name "*Logo*" -o -name "*Footer*" | grep -E "\.(tsx|jsx|ts|js)$"
```

**3. Common locations to modify:**

- `src/frontend/src/components/Footer/index.tsx`
- `src/frontend/src/components/Logo/index.tsx`
- `src/frontend/src/layout/AppLayout.tsx`

**4. Edit Footer Component:**

```bash
# Example: Edit footer
nano src/frontend/src/components/Footer/index.tsx
```

**5. Comment out or remove logo render:**

```tsx
// Before:
<a href="https://datastax.com">
  <img src={logo} alt="DataStax" />
</a>

// After:
{/* Logo removed */}
```

**6. Rebuild and Deploy:**

```bash
# Build frontend
cd src/frontend
npm install
npm run build

# Build Docker image
cd ../..
docker build -t langflow-custom:latest .

# Push to Railway (if using Railway)
docker tag langflow-custom:latest registry.railway.app/langflow-engarde:latest
docker push registry.railway.app/langflow-engarde:latest
```

---

### Option 3: Use Browser Extension (Persistent, Browser-Only)

**Install uBlock Origin or Stylus extension:**

**For uBlock Origin:**
1. Install uBlock Origin extension
2. Open uBlock settings
3. Go to "My filters"
4. Add this rule:

```
langflow.engarde.media##.langflow-logo
langflow.engarde.media##footer img
langflow.engarde.media##footer svg
```

**For Stylus:**
1. Install Stylus extension
2. Click Stylus icon → "Write style for: langflow.engarde.media"
3. Paste this CSS:

```css
/* Hide DataStax/Langflow logo */
.langflow-logo,
[class*="langflow-logo"],
[class*="datastax"],
footer img,
footer svg,
footer a[href*="datastax"],
footer a[href*="langflow"] {
  display: none !important;
}

/* Optional: Hide entire footer */
footer {
  display: none !important;
}
```

4. Save and enable the style

---

### Option 4: Reverse Proxy with CSS Injection (Advanced)

If you control the deployment (Railway), you can add a reverse proxy (nginx) that injects custom CSS:

**nginx.conf:**

```nginx
server {
    listen 80;
    server_name langflow.engarde.media;

    location / {
        proxy_pass http://langflow-server:7860;
        proxy_set_header Host $host;

        # Inject custom CSS
        sub_filter '</head>' '<style>.langflow-logo, footer img, footer svg { display: none !important; }</style></head>';
        sub_filter_once on;
    }
}
```

---

### Recommended Approach

**For quick testing:** Use Option 1 (Browser Console CSS)

**For persistent use:** Use Option 3 (Browser Extension)

**For production/team use:** Use Option 2 (Custom Docker Image)

---

## 🎉 Summary

**To paste agent code into Langflow:**

1. Open Python Function node in Langflow
2. Find "Function Code" field
3. Copy ONLY the `def run(...)` function from agent files
4. Paste into "Function Code" field
5. Click "Check & Save"

**To remove DataStax logo:**

- **Quick:** Use browser console CSS injection
- **Persistent:** Use browser extension (uBlock or Stylus)
- **Permanent:** Build custom Docker image

---

**Ready to deploy! Follow the steps above for each agent. 🚀**
