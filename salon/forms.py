from datetime import date, datetime, time
from decimal import Decimal, InvalidOperation
from zoneinfo import ZoneInfo
from flask import abort, request


def now():
    return datetime.now(ZoneInfo("Europe/Moscow")).replace(tzinfo=None)


def required(key, limit=200):
    value = request.form.get(key, "").strip()
    if not value or len(value) > limit:
        abort(400, f"Проверьте поле «{key}».")
    return value


def number(value, low=1, high=2147483647):
    try:
        result = int(value)
        if low <= result <= high:
            return result
    except (ValueError, TypeError):
        pass
    abort(400, "Проверьте числовое значение.")


def money(value):
    try:
        n = Decimal(value)
        if (
            n.is_finite()
            and 0 <= n <= Decimal("99999999.99")
            and n == n.quantize(Decimal(".01"))
        ):
            return n
    except (InvalidOperation, ValueError, TypeError):
        pass
    abort(400, "Проверьте цену.")


def day(value):
    try:
        return date.fromisoformat(value)
    except (ValueError, TypeError):
        abort(400, "Проверьте дату.")


def clock(value):
    try:
        t = time.fromisoformat(value)
        if t.tzinfo is None and not t.second and not t.microsecond:
            return t
    except (TypeError, ValueError):
        pass
    abort(400, "Проверьте время.")