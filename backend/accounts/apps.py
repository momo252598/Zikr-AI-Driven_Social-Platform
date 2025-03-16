from django.apps import AppConfig

class AccountsConfig(AppConfig): # this defines the application config
    default_auto_field = 'django.db.models.BigAutoField' # ensures that models use the recommended auto field type.
    name = 'accounts' # tells django which app this config is for
