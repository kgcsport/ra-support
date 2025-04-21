---
title: "RA Handbook"
author: "Kyle Coombs"
email: "kcoombs@bates.edu"  # ← Update this as needed
date: "`r Sys.Date()`"
output: pdf_document
fontsize: 11pt
geometry: margin=1in
---

# 🧠 Working with Me: RA Handbook

Welcome! This guide lays out how we’ll work together and what helps make this a great experience for both of us. Most tasks will feel doable—and some will feel fuzzy or hard. That’s part of the process. I don’t expect perfection, just steady work, communication, and curiosity.

---

## ⏰ Weekly Workflow

- We’ll have a **standing weekly meeting**—cancel as needed.
- You’ll **send a short agenda** the night before:
  - ✅ What you finished  
  - 🌀 What you’re stuck on  
  - ⏭️ What you plan to do next
- For bigger tasks, I may ask for:
  - A **brief plan first**
  - A **short RA memo** when you’re done (what you did, what’s odd, what to check)

---

## 🧩 Typical Tasks

You might:
- Digitize or wrangle datasets  
- Scrape or pull data from APIs  
- Spot-check papers  
- Summarize literature  
- Geocode addresses  
- Help prep data for regressions

If you’re unsure what a task means, ask or give it your best shot and flag uncertainty.

---

## 🤖 Using Gen AI (yes, do it!)

- Use Gen AI (ChatGPT, Claude, Github Copilot) to **speed up repetitive tasks**
- Don’t use it for one-off things that are faster to write yourself
- Always **test its code** and **verify math/stats answers**
- Good prompts:  
  - “What R code could I use to…?”  
  - “What does this function do?”
- Leave comments like:  
  `# GPT suggested this—seems to work but unsure why`

---

## 📁 Setup & Tools

We use **GitHub for code**, **Dropbox for data**.

Please complete the following in your first week:

1. Make a **GitHub account** and send me your username  
2. Accept repo invite within a week  
3. Make an **initial commit**  
4. Make a **branch**, change a file, and **open a pull request**  
5. Store **data in Dropbox**, and **code in GitHub**  
6. Set your **Dropbox path as an environment variable**
   - In R: `Sys.getenv("DROPBOX_DIR")`
   - In Python: `os.environ["DROPBOX_DIR"]`
7. Run the test script in the repo to confirm setup.  
   If something breaks, tell me—we’ll fix it together.
8. Sign up for **[GitHub Education](https://education.github.com/students)** to get access to GitHub Copilot for free.  
   If you’re not eligible or it doesn’t work, I can provide access to ChatGPT Plus and/or Claude Pro as needed.

---

## 📌 A Few Norms That Really Help

- **Commit your code often**—don’t wait until it's perfect
- **Write things down**, especially task lists and decisions from meetings
- **Ask when something breaks or seems too hard**
  - I may have mis-scoped it or there’s an easy fix
- **Don’t assume GPT is right**—treat it as a brainstorming assistant
- **Flag anything weird** in the data or results—trust your instincts
- Remember: part of research is **balancing clean code with working code**

---

## 👋 Final Thought

I want this to be a place where you build skills and produce work that feels meaningful. I’ll support you as we go—but you’ll also learn by doing. Let’s make this productive *and* low-stress.
