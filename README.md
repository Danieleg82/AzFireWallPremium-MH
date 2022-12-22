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

-Collection Name: RuleCollection1

-Type: Application

-Priority: 110

-Action: ALLOW

-Rule Name: Rule1

-Sourcetype = IP address

-Source = 10.0.1.0/24 

-Protocols: http:80,https

-TLS Inspection: initially DISABLED

-Destinationtype = FQDN

-Destination: ANY

=Apprulecreationpic2=

Click ADD to apply the change to the policy

## TASK2

Let's now go ahead enabling IDPS on our FW.
This will be set in Alert & Deny mode.

Since TLS Inspection is initially disabled, we will see how protection works exclusively for unencrypted traffic.

Let's select our FW Policy and locate IDPS section in the portal.
Let's choose "Alert & Deny" option and Apply changes:

=EnablingIDPS1=

## TASK3

We're now ready to test IDPS functionalities.
To do that, let's connect to the VM1 using the following credentials:

Username: adminuser
Password: "AzFWPa$$w0rd"

You can use the deployed Bastion host for accessing privately.

From your VM, now try to connect to the following site in plain HTTP:

curl -I "http://www.bing.com"

Are you able to access it?

Let's now emulate an attempt of connection to our HTTP website using a malicious user-agent included in the GET request we send out to the destination server:

curl -I -A "HaxerMen" "http://www.bing.com"

What is the output now?
Is that what you would expect?

Finally, repeat the test with the HTTPS version of same website:

With standard User-agents:
curl -I "https://www.bing.com"

...and with malicious one:
curl -I -A "HaxerMen" "https://www.bing.com"

Did you expect such result?

## TASK4

We can now review the Azure Firewall logs to show find out the requests blocked by IDS.

Wait for some minutes after having performed the above tests, then run a query on "Azure Firewall Log" logs and review the filtered requests:

=ReviewAzFWLogData1=

You can include the following line in the relevant Kusto query to parse just DENIED requests and narrow down the research to last 30 minutes:

=ReviewAzFWLogData2=

Note the IDS Signature which is currently blocking the request and the reason for blocking:

=ReviewAzFWLogData3=

## TASK5

We can now play with the functionalities of IDPS customization and decide to temporarily disable the IDPS signature triggered with our connectivity tests.

From the AzFW firewall policy configuration page, select and edit the rule 2032081 (USER_AGENTS Suspicious User-Agent (HaxerMen))

=CustomizeIDP1=

Let's configure the rule in simple ALERT mode and APPLY:

=customizeIDP2=

Let's connect back to our VM and test again the connectivity to a plain HTTP website using malicious agent:

curl -I -A "HaxerMen" "http://www.bing.com"

=TestIDPcustom1=

The Firewall is no longer dropping the request, but you will still be able to see an ALERT in FW logs related with such request.

# CHALLENGE 2: TLS Inspection and IDPS on encrypted traffic

# Task1

In this second challenge we'll proceed enabling TLS inspection on our Azure Firewall, using a test self-signed CA certificate.

In production deployments you will be using internal intermediate CA certificates provided through your internal PKI infrastructure, 
but for the purpose of this microHack the self-signed certificate is the quickest and simples approach to perform the tests.


