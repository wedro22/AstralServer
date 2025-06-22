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
                <div class="search-container">
                    <input type="text" id="projectSearch" placeholder="Поиск или создание проекта...">
                    <button type="button" id="searchButton" class="search-btn">>></button>
                </div>
            </div>
            
            <ul class="projects-list" id="projectsList" style="max-height: 400px; overflow-y: auto; overflow-x: hidden;">
                <!-- Проекты будут загружаться динамически -->
            </ul>
        </div>
    </div>

    <script>
        // Глобальная переменная для хранения проектов
        let projects = [];

        const searchInput = document.getElementById('projectSearch');
        const projectsList = document.getElementById('projectsList');

        // Загрузка проектов с сервера
        async function loadProjects() {
            try {
                const response = await fetch('/api/projects');
                const data = await response.json();
                
                if (data.success) {
                    projects = data.projects;
                    displayProjects();
                } else {
                    console.error('Ошибка загрузки проектов');
                    projectsList.innerHTML = '<li class="error">Ошибка загрузки проектов</li>';
                }
            } catch (error) {
                console.error('Ошибка при загрузке проектов:', error);
                projectsList.innerHTML = '<li class="error">Ошибка соединения с сервером</li>';
            }
        }

        // Отображение проектов в списке
        function displayProjects() {
            projectsList.innerHTML = '';
            projects.forEach(project => {
                const item = document.createElement('li');
                item.className = 'project-item';
                item.innerHTML = `
                    <div class="project-name">${project.name}</div>
                    <div class="project-date">Создан: ${project.created}</div>
                `;
                item.onclick = () => openProject(project.name);
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
        function openProject(projectName) {
            alert(`Переход к проекту "${projectName}" (заглушка)`);
        }

        // Создание нового проекта
        function createProject(name) {
            if (confirm(`Создать новый проект "${name}"?`)) {
                // Заглушка отправки на сервер
                alert('Проект отправлен на сервер (заглушка)');
                // Создаем временный объект для открытия
                openProject(name);
            }
        }

        // Обработчики событий
        searchInput.addEventListener('input', (e) => {
            const query = e.target.value.trim();
            if (query.length > 0) {
                searchProjects(query);
            } else {
                displayProjects();
            }
        });

        searchInput.addEventListener('keypress', (e) => {
            if (e.key === 'Enter') {
                handleSearch();
            }
        });

        document.getElementById('searchButton').addEventListener('click', handleSearch);

        function handleSearch() {
            const query = searchInput.value.trim();
            if (query.length > 0) {
                const exists = projects.some(p => p.name.toLowerCase() === query.toLowerCase());
                if (exists) {
                    const project = projects.find(p => p.name.toLowerCase() === query.toLowerCase());
                    openProject(project.name);
                } else {
                    createProject(query);
                }
            }
        }

        // Инициализация
        loadProjects();
    </script>
</body>
</html> 