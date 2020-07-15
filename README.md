# nat
In this project i created two subnets one is in public and one is in private and deploy an wordpress application where my wordpress is running in public subnet and my database is running in private subnet. 
The security is configure for databse is like, it has two security groups one for allow only wordpress instance through and second is bastion host. Bastion host is the instance which run in public cloud and used for go in mysql database using ssh because there is no way to go in database instance, we go in database instance may be we have to upgrade our database, troubleshoot some part in that case bastion host roles come in play.
For more details this is my blog link where i was talking same:
https://www.linkedin.com/pulse/create-public-private-subnet-internet-gateway-nat-mayank-agrawal/
