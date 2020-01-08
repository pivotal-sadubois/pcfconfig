# Demo Guide for Pivotal Build Service spring-petclinic

Short introduction to the demo and the prerequisites.

## Prerequisites

We recommend you create your own copy of the Spring Petclinic by forking the repository at `https://github.com/spring-projects/spring-petclinic`. This will allow you to make changes to the code and force a (re)build of the container image by simply commiting your changes to your master branch.

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
