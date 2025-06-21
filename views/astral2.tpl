<!DOCTYPE html>
<html lang="ru">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Astral - Проекты</title>
    <link rel="stylesheet" href="/static/astral.css">
    <link rel="stylesheet" href="/static/wave.css">
</head>
<body>
    <div class="container">
        <div class="projects-panel">
            <h1>Проекты</h1>
            
            <div class="search-box">
                <input type="text" id="projectSearch" placeholder="Поиск или создание проекта...">
            </div>
            
            <ul class="projects-list" id="projectsList" style="max-height: 400px; overflow-y: auto; overflow-x: hidden;">
                <!-- Проекты будут загружаться динамически -->
            </ul>
        </div>
    </div>

    <script>
        // Тестовые данные для демонстрации
        let projects = [
            { id: 1, name: "Мой первый проект", created: "2024-01-15" },
            { id: 2, name: "Тестовый проект", created: "2024-01-20" },
            { id: 3, name: "Рабочий проект", created: "2024-01-25" },
            { id: 4, name: "Проект номер четыре", created: "2024-01-26" },
            { id: 5, name: "Пятый проект", created: "2024-01-27" },
            { id: 6, name: "Шестой проект", created: "2024-01-28" },
            { id: 7, name: "Седьмой проект", created: "2024-01-29" },
            { id: 8, name: "Восьмой проект", created: "2024-01-30" },
            { id: 9, name: "Девятый проект", created: "2024-01-31" },
            { id: 10, name: "Десятый проект", created: "2024-02-01" }
        ];

        const searchInput = document.getElementById('projectSearch');
        const projectsList = document.getElementById('projectsList');

        // Загрузка проектов
        function loadProjects() {
            projectsList.innerHTML = '';
            projects.forEach(project => {
                const item = document.createElement('li');
                item.className = 'project-item';
                item.innerHTML = `
                    <div class="project-name">${project.name}</div>
                    <div class="project-date">Создан: ${project.created}</div>
                `;
                item.onclick = () => openProject(project.id);
                projectsList.appendChild(item);
            });
        }

        // Поиск проектов
        function searchProjects(query) {
            const items = projectsList.querySelectorAll('.project-item');
            let found = false;
            
            items.forEach(item => {
                const name = item.querySelector('.project-name').textContent.toLowerCase();
                const matches = name.includes(query.toLowerCase());
                
                item.style.display = matches ? 'block' : 'none';
                item.classList.toggle('highlighted', matches && query.length > 0);
                
                if (matches && !found) {
                    item.scrollIntoView({ behavior: 'smooth', block: 'center' });
                    found = true;
                }
            });
        }

        // Открытие проекта
        function openProject(id) {
            alert(`Переход к проекту ${id} (заглушка)`);
        }

        // Создание нового проекта
        function createProject(name) {
            if (confirm(`Создать новый проект "${name}"?`)) {
                const newProject = {
                    id: projects.length + 1,
                    name: name,
                    created: new Date().toISOString().split('T')[0]
                };
                projects.push(newProject);
                loadProjects();
                searchInput.value = '';
                openProject(newProject.id);
            }
        }

        // Обработчики событий
        searchInput.addEventListener('input', (e) => {
            const query = e.target.value.trim();
            if (query.length > 0) {
                searchProjects(query);
            } else {
                loadProjects();
            }
        });

        searchInput.addEventListener('keypress', (e) => {
            if (e.key === 'Enter') {
                const query = e.target.value.trim();
                if (query.length > 0) {
                    const exists = projects.some(p => p.name.toLowerCase() === query.toLowerCase());
                    if (exists) {
                        const project = projects.find(p => p.name.toLowerCase() === query.toLowerCase());
                        openProject(project.id);
                    } else {
                        createProject(query);
                    }
                }
            }
        });

        // Инициализация
        loadProjects();
    </script>
</body>
</html> 