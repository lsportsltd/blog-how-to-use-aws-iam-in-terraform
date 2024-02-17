from checkov.common.models.enums import CheckCategories, CheckResult
from checkov.terraform.checks.resource.base_resource_check import BaseResourceCheck


class CheckManagedPolicyARNsConflict(BaseResourceCheck):
    def __init__(self):
        name = "Check for non-effective 'aws_iam_policy_attachment' or 'aws_iam_role_policy_attachment' changes"
        id = "CUSTOM_AWS_IAM_MANAGED_POLICY_ARNS_CONFLICT"
        supported_resources = [
            'aws_iam_policy_attachment', 'aws_iam_role_policy_attachment']
        categories = [CheckCategories.IAM]
        super().__init__(name=name, id=id, categories=categories,
                         supported_resources=supported_resources)

    def scan_resource_conf(self, conf) -> CheckResult:
        actions = conf.get('__change_actions__', [])[0]
        address = conf.get('__address__', "")
        resource_type = address.split(".")[0]
        if "no-op" in actions:
            self.details.append(
                f"Using '{resource_type}' alongside 'managed_policy_arns' in 'aws_iam_role' leads to non-effective changes and a never-ending loop issue.")
            self.guideline = "https://engineering.lsports.eu/how-to-use-aws-iam-in-terraform-95be5244f562"

            return CheckResult.FAILED

        return CheckResult.PASSED


check = CheckManagedPolicyARNsConflict()
