from rest_framework.exceptions import PermissionDenied


def is_admin(user):
    return user.is_authenticated and user.role == "admin"


def admin_region(user):
    if not is_admin(user):
        return None

    if not user.region:
        raise PermissionDenied(
            "Admin account does not have a region assigned."
        )

    return user.region


def ensure_same_region(admin, obj_region):
    """
    Prevent an admin from accessing another region.
    """
    if admin.role == "admin":
        if admin_region(admin) != obj_region:
            raise PermissionDenied(
                "You do not have access to this region."
            )


def ensure_user_in_admin_region(admin, target_user):
    """
    Check another User belongs to the logged-in admin's region.
    """
    ensure_same_region(admin, target_user.region)