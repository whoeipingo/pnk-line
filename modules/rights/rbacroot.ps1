function ManRole  {

param(
    $location,
    [ValidateSet('Group','Serviceprincipal','User')]
    $PrincipalType,
    $ManagementGroupId,
    $PrincipalName,
    [ValidateSet('Contributor','Owner','Reader','User Access Administrator')]
    $Role
    
)

switch ($PrincipalType)
{

"Group"             {$id = (Get-AzADGroup -DisplayName $PrincipalName).id}
"Serviceprincipal"  {$Id = (Get-AzADServicePrincipal -DisplayName $PrincipalName).id}
"User"              {$Id = (Get-AzADUser -UserPrincipalName $PrincipalName).id}

}

$Parameters = @{
    TemplateFile      = 'C:\Data\Powershell\WVD\Ray\Pilot\rbac-mg.bicep'
    ManagementGroupId = $ManagementGroupId
    Location          = $Location
    PrincipalType     = $Principaltype
    PrincipalId       = $Id
    RoleDefinitionId  = (Get-AzRoleDefinition -Name $Role).id
}


New-AzManagementGroupDeployment @Parameters | Out-Null

}



# 1. Create IAM groups
$Owner = @(
"IAM-UM-AZ-Root_Admin_Access-Owner-P"
)

$UAAdministrator = @(
"IAM-UM-AZ-Root_Admin_Access-User_Access_Administrator-P"
)

function CreateRoleGroups {

foreach ($obj in $owner){
if (!(az ad group list --filter "displayname eq '$($obj)' " --only-show-errors | convertfrom-json)) 
    {az ad group create --display-name $obj --mail-nickname $obj} 
}

foreach ($obj in $Contributor){
if (!(az ad group list --filter "displayname eq '$($obj)' " --only-show-errors | convertfrom-json)) 
    {az ad group create --display-name $obj --mail-nickname $obj}
}

foreach ($obj in $UAAdministrator){
if (!(az ad group list --filter "displayname eq '$($obj)' " --only-show-errors| convertfrom-json)) 
    {az ad group create --display-name $obj --mail-nickname $obj}
}

}

# 1. ADD User Access Administrator @Root for logged in user
az rest --method post --url "/providers/Microsoft.Authorization/elevateAccess?api-version=2016-07-01"

# 2. Create IAM Root groups

# 3. Set Root rights for Root groups 
ManRole -location westeurope -PrincipalType Group -ManagementGroupId ((get-AzManagementGroup | Where-Object {$_.DisplayName -eq 'Tenant Root Group'}).TenantId) -PrincipalName $UAAdministrator[0] -Role 'User Access Administrator'
ManRole -location westeurope -PrincipalType Group -ManagementGroupId ((get-AzManagementGroup | Where-Object {$_.DisplayName -eq 'Tenant Root Group'}).TenantId) -PrincipalName $UAAdministrator[0] -Role 'Owner'

