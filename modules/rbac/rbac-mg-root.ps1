function ManRole  {

param(
    $location,
    [ValidateSet("Group","Serviceprincipal","User")]
    $PrincipalType,
    $ManagementGroupId,
    $PrincipalName,
    [ValidateSet("Contributor","Owner","Reader","User Access Administrator")]
    $Role
)

switch ($PrincipalType)
{

"Group"             {$id = (Get-AzADGroup -DisplayName $PrincipalName).id}
"Serviceprincipal"  {$Id = (Get-AzADServicePrincipal -DisplayName $PrincipalName).id}
"User"              {$Id = (Get-AzADUser -UserPrincipalName $PrincipalName).id}

}

$Parameters = @{
    TemplateFile      = './modules/mg/modules/rbac-mg.bicep'
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



az role assignment create --assignee-object-id ((az ad group list --query "[?displayName=='$($owner)']" | convertFrom-json).Id) --assignee-principal-type group --role "Owner" --scope "/"
# az role assignment delete --assignee (az ad group list --query "[?displayName=='$($owner)']" | convertFrom-json).objectId --role "Owner" --scope "/"

#az ad group --display-name 'IAM-UM-AZ-Root_Admin_Access-Owner-P'
#CreateRoleGroups

# 1. ADD User Access Administrator @Root for logged in user
# az rest --method post --url "/providers/Microsoft.Authorization/elevateAccess?api-version=2016-07-01"

# 2. Create IAM Root groups

# 3. Set Root rights for Root groups 
# ManRole -location westeurope -PrincipalType Group -ManagementGroupId ((get-AzManagementGroup | Where-Object {$_.DisplayName -eq 'Tenant Root Group'}).TenantId) -PrincipalName $UAAdministrator[0] -Role 'User Access Administrator'
# ManRole -location westeurope -PrincipalType Group -ManagementGroupId ((get-AzManagementGroup | Where-Object {$_.DisplayName -eq 'Tenant Root Group'}).TenantId) -PrincipalName $UAAdministrator[0] -Role 'Owner'
# az group list --query "[?location=='westeurope']"

# $test = az ad group show --group IAM-UM-AZ-Root_Admin_Access-Owner-P | ConvertFrom-Json
# write-output $test.objectId
# az role assignment create --assignee-object-id $test.objectId --assignee-principal-type group --role "Reader" --scope "/"
# az role assignment create --assignee-object-id '0641a1bb-db45-458c-8178-f901d5d9a54b' --assignee-principal-type group --role "Contributor" --scope "/"

     # - shell: pwsh
        #name: 'Test code'
        #id: test
        #run: |
        
## Assign Root roles to Admin Root Groups AzureAD
#az role assignment create --assignee-object-id (az ad group show --group ($ENV:az_rootadmin_group_owner) | ConvertFrom-Json).id --assignee-principal-type group --role "Owner" --scope "/"
#az role assignment create --assignee-object-id (az ad group show --group ($ENV:az_rootadmin_group_uaa) | ConvertFrom-Json).id --assignee-principal-type group --role "User Access Administrator" --scope "/"
## Assign Git account to Azure Admin Root groups
#az ad group member add --group $ENV:az_rootadmin_group_uaa --member-id (az ad sp list --display-name pnk-pipeline-customers | convertFrom-JSON).id
#az ad group member add --group $ENV:az_rootadmin_group_owner --member-id (az ad sp list --display-name pnk-pipeline-customers | convertFrom-JSON).id

# $test = (get-AzManagementGroup | Where-Object {$_.DisplayName -eq 'Root Management Group'}).TenantId
$test = (az account management-group list --query "[?displayName=='Root Management Group']" | convertFrom-json).displayname
$test1 = 'Dit is geen wachtwoord'
#$test = (get-AzManagementGroup | Where-Object {$_.DisplayName -eq 'Tenant Root Group'}).TenantId
# $test = "Testje123"
Write-Output "rootid= $($test)" >> $Env:GITHUB_OUTPUT
Write-Output "grapjas= $($test1)" >> $Env:GITHUB_OUTPUT
Get-Content $Env:GITHUB_OUTPUT

