In this microHack we will test the functionalities introduced by Azure Firewall Premium SKU

The environment is composed by a simple Windows VM with internet traffic protected by Azure Firewall Premium.
All is deployed in the same VNET with no particular routing configurations.

# DEPLOYMENT AND PRELIMINARY CONFIGURATIONS

## TASK1

Let's start with the deployment of the environment:

xxxxxxx

## TASK2

After our environment is deployed, let's proceed enabling Diagnostic logging on the FW:

=enableDiagpic1=

=enableDiagpic2=



# CHALLENGE1:  IDPS for unencrypted traffic

## TASK1

We will now proceed creating a basic outbound ApplicationRule which will initially allow any kind of outbound internet connection from our internal subnet.

Let's find our FW Policy from portal and let's select "Add a rule collection" under the "Application rules" section

=Apprulecreationpic1=

The rule will have the following characteristics:

Collection Name: RuleCollection1
Type: Application
Priority: 110
Action: ALLOW

Rule Name: Rule1
Sourcetype = IP address
Source = 10.0.1.0/24 
Protocols: http:80,https
TLS Inspection: initially DISABLED
Destinationtype = FQDN
Destination: ANY

=Apprulecreationpic2=

Click ADD to apply the change to the policy

## TASK2

Let's now go ahead enabling IDPS on our FW.
This will be set in Alert & Deny mode.

Since TLS Inspection is initially disabled, we will see how protection works exclusively for unencrypted traffic.

Let's select our FW Policy and locate IDPS section in the portal.
Let's choose "Alert & Deny" option and Apply changes:

=EnablingIDPS1=