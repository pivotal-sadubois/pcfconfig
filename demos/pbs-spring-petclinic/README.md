# Demo Guide for Pivotal Build Service spring-petclinic

This demo demonstrates to capability of building an application with the Pivotal Build Service (PKS) shown on the Spring Boot application Spring PetClinic. The different demo scripts allows to deploy the containers eather to Docker Hub or the Harbor Registry. The Deploy scripts can be used as an addon to demonstrate how to deploy PedClinic as a Kubernetes bassed application on PKS, AKS or GKE environments. The following table shows the demo scripts available with a short description.

| Script | Description |
| --- | --- |
| Build_PetClinic_PKS.sh | Build the application with the Pivotal Build Service (PBS) and deploy the container to the public Docker Registry (index.docker.io) or the Harbor Registry. This demo requires a PKS cluster deployed (deplyoPCF) including PBS Build Service and an account on docker.io account |
| Build_PetClinic_Hosted.sh | Build the application with the Pivotal Build Service (PBS) and deploy the container to the Harbor Registry hosted by Pivotal. This demo does not requires a PKS cluster deployed but an account for the Build Service (https://pbs.picorivera.cf-app.com), see the prerequisists |
| Deploy_PetClinic_PKS.sh | Deploy the build PetClinic docker container as Kubernets project to (PKS,PKE,AKS,GKE and Minikube) |

## Prerequisites

As a prerequisites to run the demos it's required to have the following steps completed
- deploy (with deployPCF) a PKS environment with Harbor Registry and Pivotal Build Service (PBS) on your favorite Cloud
- requst access to the hosted Build Service (PBS) environment (https://pbs.picorivera.cf-app.com) by contacting Matthew Gibson by slack or email (mgibson@pivotal.io). 
- forking the repository at `https://github.com/spring-projects/spring-petclinic` into your GitHub spaces to make changes to the code and force a (re)build of the container image by simply commiting your changes to your master branch.

## Image Rebuild by Config Change

You can trigger an image rebuild by 
- Changing the `BP_JAVA_VERSION` in the `files/spring-petclinic-*-template.yml` file for Docker or Harbor. 
- Running the Pivotal Build CLI to configure this change `pb image apply -f /tmp/spring-petclinic-harbor.yml`

## Image Rebuild by Source Code Change

Another way to trigger the rebuild is to change the source code in your copy of the code. A simple and visual change in the code is to change the Welcome message of the Pet Clinic. Take your preferred editor or use the Gibhub UI to edit the messages.properties file (simply click the pencil icon on the UI).

`https://github.com/<YOUR-GITHUB-ACCOUNT>/spring-petclinic/src/main/resources/messages/messages.properties`

- Change the first line from `welcome=Welcome` to `welcome=Grüezi`
- Commit your change
- Watch the next build with `pb image builds ...`
