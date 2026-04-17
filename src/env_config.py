import sys, logging

DEBUG_MODE = True

class Color:
    RESET  = "\033[0m"
    RED    = "\033[31m"
    GREEN  = "\033[32m"
    YELLOW = "\033[33m"
    BLUE   = "\033[34m"

class ColorFormatter(logging.Formatter):
    def format(self, record):
        msg = record.getMessage()

        if   record.levelno == logging.DEBUG:    color = Color.BLUE
        elif record.levelno == logging.INFO:     color = Color.GREEN
        elif record.levelno == logging.WARNING:  color = Color.YELLOW
        elif record.levelno == logging.ERROR:    color = Color.RED
        else:                                    color = Color.RESET

        msg = f"{color}{msg}{Color.RESET}"
        return f"[{record.levelname}] [{record.name}] {msg}"

def _setup_logging():
    logger = logging.getLogger()
    level = logging.DEBUG if DEBUG_MODE else logging.INFO
    logger.setLevel(level)
    handler = logging.StreamHandler(sys.stdout)
    formatter = ColorFormatter("[%(levelname)s] [%(name)s] %(message)s")

    handler.setFormatter(formatter)
    logger.addHandler(handler)

_setup_logging()

def get_logger(name):
    return logging.getLogger(name)
