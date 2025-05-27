# Todo App - Full Stack Application

A modern, full-stack Todo application built with Next.js, Django, and PostgreSQL, all containerized with Docker.

## 🚀 Features

- **Frontend**: Next.js 14 with TypeScript and Tailwind CSS
- **Backend**: Django REST Framework with PostgreSQL
- **Database**: PostgreSQL 15
- **Containerization**: Docker and Docker Compose
- **Modern UI**: Responsive design with beautiful animations
- **Full CRUD**: Create, Read, Update, Delete todos
- **Real-time Updates**: Instant UI updates
- **Filtering**: View all, active, or completed todos
- **Statistics**: Track your productivity

## 🛠️ Tech Stack

### Frontend
- **Next.js 14** - React framework with App Router
- **TypeScript** - Type safety
- **Tailwind CSS** - Utility-first CSS framework
- **Axios** - HTTP client for API calls

### Backend
- **Django 5.1** - Python web framework
- **Django REST Framework** - API development
- **PostgreSQL** - Relational database
- **django-cors-headers** - CORS handling

### DevOps
- **Docker** - Containerization
- **Docker Compose** - Multi-container orchestration

## 📋 Prerequisites

- Docker and Docker Compose installed on your machine
- Git (to clone the repository)

## 🚀 Quick Start

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd ci-cd-demo
   ```

2. **Start the application**
   ```bash
   docker-compose up --build
   ```

3. **Access the application**
   - Frontend: http://localhost:3000
   - Backend API: http://localhost:8000
   - Admin Panel: http://localhost:8000/admin

## 📁 Project Structure

```
ci-cd-demo/
├── backend/                 # Django backend
│   ├── todoproject/        # Django project settings
│   ├── todos/              # Todo app
│   ├── requirements.txt    # Python dependencies
│   ├── Dockerfile         # Backend Docker configuration
│   └── .dockerignore      # Backend Docker ignore
├── frontend/               # Next.js frontend
│   ├── src/
│   │   ├── app/           # Next.js app directory
│   │   ├── components/    # React components
│   │   ├── services/      # API services
│   │   └── types/         # TypeScript types
│   ├── package.json       # Node.js dependencies
│   ├── Dockerfile        # Frontend Docker configuration
│   └── .dockerignore     # Frontend Docker ignore
├── docker-compose.yml     # Multi-container configuration
└── README.md             # This file
```

## 🔧 Development

### Running Individual Services

**Backend only:**
```bash
cd backend
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r requirements.txt
python manage.py migrate
python manage.py runserver
```

**Frontend only:**
```bash
cd frontend
npm install
npm run dev
```

### API Endpoints

The Django backend provides the following REST API endpoints:

- `GET /api/todos/` - List all todos
- `POST /api/todos/` - Create a new todo
- `GET /api/todos/{id}/` - Get a specific todo
- `PATCH /api/todos/{id}/` - Update a todo
- `DELETE /api/todos/{id}/` - Delete a todo
- `PATCH /api/todos/{id}/toggle_completed/` - Toggle todo completion

### Database

The application uses PostgreSQL with the following configuration:
- Database: `todoapp`
- User: `todouser`
- Password: `todopass`
- Host: `db` (in Docker) or `localhost` (local development)
- Port: `5432`

## 🐳 Docker Commands

**Start all services:**
```bash
docker-compose up
```

**Start in background:**
```bash
docker-compose up -d
```

**Rebuild and start:**
```bash
docker-compose up --build
```

**Stop all services:**
```bash
docker-compose down
```

**View logs:**
```bash
docker-compose logs
docker-compose logs backend
docker-compose logs frontend
```

**Access container shell:**
```bash
docker-compose exec backend bash
docker-compose exec frontend sh
```

## 🎨 UI Features

- **Responsive Design**: Works on desktop, tablet, and mobile
- **Modern Interface**: Clean and intuitive user experience
- **Real-time Updates**: Instant feedback for all actions
- **Loading States**: Visual feedback during API calls
- **Error Handling**: User-friendly error messages
- **Statistics Dashboard**: Track your productivity
- **Filtering**: Easy switching between todo states

## 🔒 Environment Variables

### Backend
- `POSTGRES_DB`: Database name (default: todoapp)
- `POSTGRES_USER`: Database user (default: todouser)
- `POSTGRES_PASSWORD`: Database password (default: todopass)
- `POSTGRES_HOST`: Database host (default: db)
- `POSTGRES_PORT`: Database port (default: 5432)

### Frontend
- `NEXT_PUBLIC_API_URL`: Backend API URL (default: http://localhost:8000)

## 🚀 Production Deployment

For production deployment, consider:

1. **Environment Variables**: Use secure environment variables
2. **Database**: Use managed PostgreSQL service
3. **Static Files**: Configure static file serving
4. **HTTPS**: Enable SSL/TLS
5. **Monitoring**: Add logging and monitoring
6. **Scaling**: Use container orchestration (Kubernetes, Docker Swarm)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## 📝 License

This project is open source and available under the [MIT License](LICENSE).

## 🐛 Troubleshooting

**Common Issues:**

1. **Port conflicts**: Make sure ports 3000, 8000, and 5432 are available
2. **Docker issues**: Try `docker-compose down` and `docker-compose up --build`
3. **Database connection**: Wait for the database to be ready (health check included)
4. **CORS errors**: Check that the frontend URL is in Django's CORS settings

**Reset everything:**
```bash
docker-compose down -v
docker-compose up --build
```

This will remove all containers, volumes, and rebuild from scratch. # Todo App - Deployment triggered on Mon May 26 19:41:36 CDT 2025
