# Quick Tutorial on Deploying a Sample Application with Helm Charts 
With Openshift 4.3, Helm 3 is GA with the platform. 

### Why Use Helm 3
Helm is a package manager for Kubernetes that helps create helm charts, i.e.templated packages,  that will contain all Kubernetes manifests needed to deploy an application on a cluster. 

### Helm 3 vs Openshift Templates 
If are coming from Openshift 3.x, you may recall Openshift Templates. A very similar principal that exclusively worked with RedHat Openshift to templatize Kuberentes manifests to support enterprise CI/CD solutions. While, Openshift templates do still reside in OCP 4.x, this feature is no longer being improved. Helm 3 is the go-to solution for Openshift and Kubernetes alike.

### Helm Supports 

**I. Natively supports Kubernetes-** easy to translate your Kubernetes manifest to helm charts 

**II. Templating-** easy syntax to templatize the kubernetes manifests for supporting Devops practices 

**III. Management of Installations and upgrades of charts-** easy to upgrade and audit deployments 

**IV. Built-in rollbacks to a previous version -** easy to revert to a previous application state 

**V. Repositories-** Helm supports storing charts in remote or local helm repositories 

## Deploy Sample Application 

**I. Pre-requisites**  
1. Access to an Openshift Cluster 
2. Install Helm 3 cli tool. It can be located from the Command Line Tools page in the Openshift Console. 

**II. Create Namespace and build the spring-boot image**  
First create a namespace to deploy your sample application: `oc new-project <project-name>`

Second, use the S2I BuildConfig Manifest in the ./openshift/app/bc-s2i.yaml to build the image in your namespace: `oc apply -f ../app/bc-s2i.yaml`

Kick off a build: `oc start-build spring-boot-helloworld-s2i`

**III. Deploy the Application via the Helm-Chart**
For this sample, we will be installing this local chart 

1. Install a local chart the first time via the following command: `helm install spring-boot-helloworld ./ -f values.yaml --create-namespace -n <project-name>`

2. Check the pod is healthy: `oc get pods`

3. With Helm check what releases you have in the this namespace: 
```
   $ helm list 
NAME                    NAMESPACE       REVISION        UPDATED                                 STATUS          CHART                           APP VERSION
spring-boot-helloworld  spring-danny    1               2021-11-22 12:58:41.329422218 -0500 EST deployed        spring-boot-helloworld-0.1.0    1.0.0
```

4. Now we'll play with helm upgrades: 
    * Update the bc-s2i.yaml, change the output imagestream tag from latest to 2.0 via the command `oc edit bc spring-boot-helloworld-s2i`: 
    ```
    to:
      kind: "ImageStreamTag"
      name: "spring-boot-helloworld-s2i:2.0"
    ```
    * Kick off a new build and wait for it to complete : `oc start-build spring-boot-helloworld-s2i`
    * Update the tag field in the values.yaml file to 2.0
    * Now we can update the appVersion of the helm chart and upgrade the app via helm. 
      * In Chart.yaml change the appVersion to 2.0.0 
    * You are ready to upgrade the application via helm: `helm upgrade spring-boot-helloworld ./ -f values.yaml`. With `helm list` you should see APP VERSION = 2.0.0, and with `oc get pods` a new application pod being spun up. 

5. To do a complete tear down of the application you can run: `helm uninstall <spring-boot-helloworld>`

##  Additional Resources 
[Openshift 4.3: Deploy Application with Helm 3](https://cloud.redhat.com/blog/openshift-4-3-deploy-applications-with-helm-3)

[Helm Best Practices](https://codefresh.io/docs/docs/new-helm/helm-best-practices/)