from bottle import route, run, response
import threading
import queue

# Очередь для передачи сообщений из терминала в HTTP-обработчик
message_queue = queue.Queue()

@route('/')
def long_polling():
    try:
        # Ждём сообщение из очереди (с таймаутом, чтобы проверить, жив ли клиент)
        message = message_queue.get(timeout=120)  # Таймаут 30 секунд
        return f"Сообщение: {message}"
    except queue.Empty:
        return "Таймаут, попробуйте снова"

def terminal_input_listener():
    while True:
        user_input = input("Введите сообщение для отправки клиентам: ")
        message_queue.put(user_input)

if __name__ == '__main__':
    # Запускаем поток для чтения ввода из терминала
    threading.Thread(target=terminal_input_listener, daemon=True).start()

    # Запускаем сервер Bottle
    run(host='localhost', port=8080, debug=True)