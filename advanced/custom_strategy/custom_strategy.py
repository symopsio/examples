from sym.sdk.strategies import AccessStrategy
import requests


class CustomStrategy(AccessStrategy):
    def fetch_remote_identity(self, user):
        """This method determines how to identify this Sym user in the third party system.

        For this example, we'll use the user's email address.
        """
        return user.email

    def headers(self):
        """This is a helper method to generate the headers needed to authenticate with the
        third party system. It is not required in all Custom Strategy implementations.
        """
        secrets = self.integration.settings["secrets"]

        if not secrets:
            raise RuntimeError("API key must be set as secret 0 in Terraform")

        api_key = secrets[0].retrieve_value()
        return {"Authorization": f"Bearer {api_key}"}

    def escalate(self, target_id, event):
        """This method executes after a user's request has been approved. It should elevate
        their permissions in the third party system.
        """

        # Get the user's identity in the third party system (in this case, their email).
        requester = self.get_requester_identity(event)

        # Using the user's ID and requested target, make an API call to a third party system to escalate their permissions.
        payload = {
            "user_id": requester,
            "resource_id": target_id,
        }

        requests.post("https://some-api.invalid/escalate", headers=self.headers(), json=payload)

    def deescalate(self, target_id, event):
        requester = self.get_requester_identity(event)

        # Using the user's ID and requested target, make an API call to a third party system to deescalate their permissions.
        payload = {
            "user_id": requester,
            "resource_id": target_id,
        }

        requests.post("https://some-api.invalid/deescalate", headers=self.headers(), json=payload)
