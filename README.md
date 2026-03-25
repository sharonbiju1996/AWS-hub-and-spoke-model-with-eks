# AWS-hub-and-spoke-model-with-eks
IAC for hub and spoke model with hub and spoke
![WhatsApp Image 2026-03-25 at 10 38 53 AM](https://github.com/user-attachments/assets/556c1380-5e0a-47a4-a428-f11312b021db)

In this archiechture first we plan to use with Vnet peering.The Core Problem: VPC Peering Does NOT Support Transitive Routing
VPC peering does not support transitive pe AWSering relationships. Critically — if VPC A has a NAT Gateway, resources in VPC B (a spoke) cannot use that NAT Gateway to access the internet through VPC A. Similarly, if VPC A has an internet gateway, resources in VPC B can't use it to reach the internet.
This is a hard architectural limitation of VPC Peering — it is by design.

✅ The Solution: Use AWS Transit Gateway (TGW) for Centralized Egress
To centralize NAT traffic, you create a Central Egress VPC in a network services account. Then, your Transit Gateway route configuration sends internet-bound traffic from spoke VPCs to the Central Egress VPC (which hosts the NAT Gateway), as well as the reverse path. AWS
Architecture (Hub & Spoke with TGW)
Spoke VPC 1  ──┐ 
Spoke VPC 2  ──┼──► AWS Transit Gateway ──► Central Egress VPC (NAT GW + IGW) ──► Internet
Spoke VPC 3  ──┘

10.1.0.0/16 = vpc1
10.2.0.0/16
10.3.0.0/16  in hub and spoke model two VPC do not overlapp each other.
Each spoke VPC only needs to connect to the Transit Gateway to gain access to other connected VPCs and shared services like NAT Gateway egress traffic. This centralization simplifies the complexity of managing these resources across several VPCs. AWS

🛠️ Step-by-Step: What To Configure
1. Central Egress VPC

Create a public subnet with a NAT Gateway and Internet Gateway
Attach this VPC to the Transit Gateway

2. Spoke VPC 1 Route Table
Add a default route pointing to TGW:
DestinationTarget0.0.0.0/0Transit Gateway ID
3. Transit Gateway Route Table
Add a default route pointing to the Egress VPC attachment:
DestinationTarget0.0.0.0/0Egress VPC TGW Attachment
4. Central Egress VPC Route Table (private subnet)
DestinationTarget0.0.0.0/0NAT GatewaySpoke CIDR (e.g. 10.1.0.0/16)Transit Gateway
5. Central Egress VPC Route Table (public subnet)
DestinationTarget0.0.0.0/0Internet GatewaySpoke CIDRTransit Gateway

💡 Cost Tip
To save on Transit Gateway and NAT Gateway data processing costs, AWS recommends creating a Gateway VPC Endpoint for each VPC that requires communication to Amazon S3 or DynamoDB in the same region — so that traffic goes directly without passing through the NAT Gateway. AWS

📄 Official AWS Documentation Links
ResourceURLVPC Peering Limitationshttps://docs.aws.amazon.com/vpc/latest/peering/vpc-peering-basics.htmlNAT Gateway Docshttps://docs.aws.amazon.com/vpc/latest/userguide/vpc-nat-gateway.htmlTransit Gateway Routinghttps://docs.aws.amazon.com/vpc/latest/tgw/how-transit-gateways-work.htmlCentralized NAT with TGW (Blog)https://aws.amazon.com/blogs/networking-and-content-delivery/using-nat-gateways-with-multiple-amazon-vpcs-at-scale/Multi-VPC Architecture Whitepaperhttps://docs.aws.amazon.com/whitepapers/latest/building-scalable-secure-multi-vpc-network-infrastructure/
Bottom line: VPC Peering alone cannot solve this — you must use AWS Transit Gateway to route Spoke VPC internet traffic through a centralized NAT Gateway. Sonnet 4.6Extended

# API gateway with REST API

We can set the custom domains using AWS API gateway so that we can use a single api gateway for multiple environments. From apigateway using VPC link to NLB and from there to ingress. In ingress we have configured the path based routing and host based routing



