import logging

logger = logging.getLogger(__name__)

def notify_admin(reminder, trigger_time):
    print("✨ REMINDER", reminder.message, trigger_time)
    logger.info("============ %s | %s", reminder.message, trigger_time)

