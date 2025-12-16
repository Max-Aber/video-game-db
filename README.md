# Video Game Store Database

A MySQL database system for managing a video game retail store, including inventory, sales, customers, employees, and business operations.

---

## 📋 Prerequisites

Choose **ONE** of the following setup methods:

### Option A: Docker (No MySQL Installation Required)

- [Docker Desktop](https://www.docker.com/products/docker-desktop) installed and running
- Git Bash (Windows) or Terminal (Mac/Linux)

### Option B: Local MySQL

- MySQL 8.0 or higher installed
- Git Bash (Windows) or Terminal (Mac/Linux)

---

## 🚀 Quick Start

### Option A: Using Docker (Recommended)

**1. Install Docker Desktop**

- Download from: https://www.docker.com/products/docker-desktop
- Install and restart your computer
- Start Docker Desktop (wait for it to fully start)

**2. Verify Docker is Running**

```bash
docker --version
```

**3. Navigate to Project**

```bash
cd path/to/video-game-db
```

**4. Set Your Password**
Edit `.env` file and set your MySQL password:

```env
MYSQL_ROOT_PASSWORD=your-password-here
```

**5. Start MySQL Container**

```bash
docker-compose up -d
```

Wait 10-20 seconds for MySQL to initialize.

**6. Load the Database**

```bash
cd scripts
./load.sh --docker
```

When prompted, enter the password from your `.env` file.

**7. Verify Success**

```bash
mysql -u root -p -h localhost --port=3307 -e "USE video_game_store; SHOW TABLES;"
```

---

### Option B: Using Local MySQL

**1. Install MySQL**

- Download MySQL 8.0+ from: https://dev.mysql.com/downloads/mysql/
- Remember your root password during installation

**2. Add MySQL to PATH (Windows)**

- Search "Environment Variables"
- Edit "Path" variable
- Add: `C:\Program Files\MySQL\MySQL Server 8.x\bin`
- Restart your terminal

**3. Verify MySQL**

```bash
mysql --version
```

**4. Navigate to Project**

```bash
cd path/to/video-game-db
```

**5. Load the Database**

```bash
cd scripts
./load.sh --local
```

When prompted, enter your MySQL root password.

**6. Verify Success**

```bash
mysql -u root -p -e "USE video_game_store; SHOW TABLES;"
```

---

## 🔧 Running Shell Scripts on Windows

If you see an error like `'.' is not recognized...` when running `./load.sh`:

**Use Git Bash (comes with Git for Windows):**

1. Install Git from: https://git-scm.com/downloads
2. Right-click in your project folder → "Git Bash Here"
3. Run: `./load.sh --docker` (or `./load.sh --local` for local MySQL)

**Alternative: Use WSL (Windows Subsystem for Linux)**

```bash
wsl bash scripts/load.sh
```

---

## 📁 Project Structure

```
video-game-db/
├── README.md                    # This file
├── docker-compose.yml           # Docker configuration
├── .env                         # MySQL password (DO NOT COMMIT)
├── .gitignore                   # Git exclusions
├── /docs
│   ├── erd.png                 # Entity Relationship Diagram
│   └── design_rationale.md     # Design documentation
├── /sql
│   ├── 01_schema.sql           # Database schema (DDL)
│   ├── 02_seed.sql             # Sample data
│   ├── 03_views.sql            # Database views
│   ├── 04_functions.sql        # Stored procedures/functions
│   ├── 05_triggers.sql         # Business rule triggers
│   ├── 06_indexes.sql          # Performance indexes
│   ├── 07_queries.sql          # Sample queries
│   └── 08_transactions.sql     # ACID demonstration
├── /scripts
│   ├── load.sh                 # Database setup script
│   └── explain.sh              # Query analysis script
└── /data
    └── *.csv                   # Data files (if used)
```

---

## 🗄️ Database Management

### Stop Docker Container

```bash
docker-compose down
```

### Restart Docker Container

```bash
docker-compose up -d
```

### Wipe Database & Start Fresh (Docker)

```bash
docker-compose down -v
docker-compose up -d
cd scripts
./load.sh --docker
```

### Wipe Database & Start Fresh (Local MySQL)

```bash
cd scripts
./load.sh --local
```

The script automatically drops and recreates the database.

### View Container Logs

```bash
docker-compose logs -f mysql
```

### Connect to Database

**Using MySQL Workbench:**

- Host: `localhost`
- Port: `3307` (Docker) or `3306` (Local)
- Username: `root`
- Password: From `.env` file or your local MySQL password

**Using Command Line:**

```bash
# Docker
mysql -u root -p -h localhost --port=3307 video_game_store

# Local MySQL
mysql -u root -p video_game_store
```

---

## 🎓 For Graders

### Quick Setup (No MySQL Installation Needed)

```bash
# 1. Start Docker Desktop
# 2. Run these commands:
docker-compose up -d
cd scripts
./load.sh --docker
# Enter password: video-game-lover123
```

### Verify Database

```bash
mysql -u root -p -h localhost --port=3307 -e "USE video_game_store; SELECT COUNT(*) FROM Product;"
```

---

## ⚠️ Troubleshooting

### "mysql: command not found"

- **Docker users:** Make sure Docker container is running: `docker ps`
- **Local users:** MySQL not in PATH. See "Add MySQL to PATH" section above
- **Windows users:** Use Git Bash, not CMD or PowerShell

### "Port 3306 already in use"

- Your local MySQL is running on port 3306
- Use Docker mode instead: `./load.sh --docker`
- Or use local mode on a different port: `./load.sh --local 3307`
- Or stop local MySQL: Windows Services → MySQL80 → Stop

### "Access denied for user 'root'"

- **Docker:** Check password in `.env` file
- **Local:** Use your MySQL installation password

### "Can't connect to MySQL server"

- **Docker:** Wait 20 seconds after `docker-compose up -d`
- **Docker:** Verify container is running: `docker ps`
- **Local:** Start MySQL service in Windows Services

### VS Code Terminal doesn't recognize mysql

- Close VS Code completely
- Reopen VS Code
- Try again

---

## 🔐 Security Notes

- The `.env` file contains your MySQL password
- **DO NOT** commit `.env` to git (already in `.gitignore`)
- Change the default password in `.env` before deploying
- For production, use more secure password management

---

## 📝 Development

### Running Queries

```bash
mysql -u root -p --port=3307 video_game_store < sql/07_queries.sql
```

### Testing Transactions

```bash
mysql -u root -p --port=3307 video_game_store < sql/08_transactions.sql
```

### Analyzing Query Performance

```bash
cd scripts
./explain.sh
```
