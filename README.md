# ☪ Halal.com

**Halal & Haram Product Tracker for Muslims**  
Built by [Halalbillionaires](https://halalbillionaires.com)

---

## 📱 Screenshots
> Dark green glassmorphism UI — inspired by Tarteel & Muslim Pro

---

## 🚀 Features

- 🔍 **Search** products, brands, and ingredients
- 📱 **Barcode Scanner** — instant halal/haram result
- 🤖 **AI Analysis** via Groq (ingredient breakdown)
- 🟢🔴🟡 **Halal / Haram / Doubtful** status with reasons
- ❤️ **Favorites** — save your trusted products
- 🚩 **Report** wrong info or submit new products
- 👤 **User Accounts** via Supabase Auth
- 🌙 **Dark Mode** — always on (Islamic green theme)

---

## 🛠 Tech Stack

| Layer | Technology |
|-------|-----------|
| App | Flutter |
| Backend | Supabase |
| Database | PostgreSQL (via Supabase) |
| AI | Groq API (LLaMA 3.3 70B) |
| Build | GitHub Actions |

---

## ⚙️ Setup Guide

### Step 1 — Clone the repo
```bash
git clone https://github.com/YOUR_USERNAME/halal-com.git
cd halal-com
```

### Step 2 — Create `.env` file
```bash
cp .env.example .env
```
Fill in your keys:
```
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
GROQ_API_KEY=gsk_your-groq-key
```

### Step 3 — Set up Supabase
1. Go to [supabase.com](https://supabase.com)
2. Create new project → name it `halal-com`
3. Go to SQL Editor
4. Copy & run the contents of `supabase/schema.sql`
5. Get your URL + Anon Key from Settings → API

### Step 4 — Get Groq API Key
1. Go to [console.groq.com](https://console.groq.com)
2. Create free account
3. Generate API Key
4. Add to `.env`

### Step 5 — Add GitHub Secrets
Go to your repo → Settings → Secrets → Actions → New secret:
- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`  
- `GROQ_API_KEY`

### Step 6 — Build APK
Push to `main` branch → GitHub Actions automatically builds APK.  
Download from Actions tab → Artifacts.

---

## 📁 Project Structure

```
lib/
├── main.dart              # App entry point
├── theme/
│   └── app_theme.dart     # Colors, fonts, styles
├── models/
│   ├── product_model.dart
│   ├── brand_model.dart
│   └── user_model.dart
├── services/
│   ├── supabase_service.dart  # All DB operations
│   └── groq_service.dart      # AI ingredient analysis
├── screens/
│   ├── splash_screen.dart
│   ├── home_screen.dart
│   ├── search_screen.dart
│   ├── scanner_screen.dart
│   ├── product_detail_screen.dart
│   ├── favorites_screen.dart
│   ├── profile_screen.dart
│   ├── report_screen.dart
│   └── auth/
│       ├── login_screen.dart
│       ├── register_screen.dart
│       └── forgot_password_screen.dart
└── widgets/
    ├── halal_badge.dart
    ├── product_card.dart
    └── bottom_nav.dart
```

---

## 🗄 Database Tables

- `profiles` — User accounts
- `products` — Halal/Haram product database
- `brands` — Brand status tracking
- `favorites` — User saved products
- `reports` — Community submissions & corrections

---

## 🤝 Contributing

1. Fork the repo
2. Create feature branch
3. Submit a Pull Request

---

## 📄 License

MIT License — Built with ❤️ by Halalbillionaires

---

*بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ*
