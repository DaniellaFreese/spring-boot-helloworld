# Helm Chart Tutorial 

In this guide we will walk through the basics of build a helm chart from scratch with Helm 3. 

The pre-requisistes for this tutorial: 
1. access to an openshift cluster 
2. helm 3 cli tool - available in the openshift command line tools 
3. a decent yaml editor - Atom, Sublime, VSCode 


The output of this tutorial will be a helm-chart of this helloworld springboot application that successfully runs on an openshift cluster. 

## Helm Templating Language
Helm is a packaging and templating engine for Kubernetes. In the background, it is using the Go templating engine and [Go Sprig Package](https://github.com/Masterminds/sprig) (template functions for Go templates) for building charts. In translation what does that really mean? The helm documentation actually provides a nice summary: 
```
While we talk about the "Helm template language" as if it is Helm-specific, it is actually a combination of the Go template language, some extra functions, and a variety of wrappers to expose certain objects to the templates. Many resources on Go templates may be helpful as you learn about templating.
```

## Creating Your First Helm Chart 
Create a boilder plate helm chart, called hello-springboot with the helm cli tool: `helm create hello-springboot`

Lets take a look at the directory structure create: 
```
$ tree hello-springboot/
hello-springboot/
├── charts
├── Chart.yaml
├── templates
│   ├── deployment.yaml
│   ├── _helpers.tpl
│   ├── hpa.yaml
│   ├── ingress.yaml
│   ├── NOTES.txt
│   ├── serviceaccount.yaml
│   ├── service.yaml
│   └── tests
│       └── test-connection.yaml
└── values.yaml

3 directories, 10 files
```
1. **Chart.yaml :** **Required**, contains the metadata for the chart. Information that an end user would find helpful. It provides, the name, description for the chart. The other two important attributes, version and appVersion. Version = the version of the chart. AppVersion is the version of the microservice/app itself. For standard developers, when the microservice is being upgraded on a cluster, it is the `appVersion` that is incremented not the `version`. 
   
2. **templates/** **Required**
   1. **various templates :** **Required** Every yaml file found in this folder is a go-template. Helm will be pick up any yaml files in this directly, and process it when you install/upgrade the helm chart on the cluster. 
   2. **_helpers.tpl :** **Optional** A place to put template helpers that you can re-use throughout the chart
   3. **tests/ :** **Optional** tests that validate that the chart works as expected when it is installed
3. **charts/ :**  **Optional** A directory containing any charts upon which this chart depends
4. **values.yaml :** The default configuration values for this chart, that later is duplicated per env. 
5. **NOTES.txt :** **Optional** This is a templated, plaintext file that is printed after the chart is successfully deployed. It's great place to describe the next steps for using a chart once it's deployed. 

## Customizing the Helm Chart 
Now that we've quickly reviewed all the files/directories. Lets's go ahead and blow away everything in the templates directory and start from scratch.  
`rm -r templates/* && rm values.yaml`

We will templatize the resources in the `openshift/app/ directory`, skipping over the buildconfigs. Copy `app/deployment.yaml` and `app/svc.yaml` to the templates directory. 

### Templatize Deployment.yaml 
1. Replace the micro-sevice name `spring-boot-helloworld` with a variable. Anywhere we see `spring-boot-helloworld` we will replace it with: `{{ .Values.appName }}`, Example: 
    ```
    apiVersion: apps/v1
    kind: Deployment
    metadata:
    name: {{ .Values.appName }}
    labels:
        app: {{ .Values.appName }}
    ...
    ```
2. Update the values.yaml with the corresponding variable: 
   ```
    # Default values for hello-springboot.
    # This is a YAML-formatted file.
    # Declare variables to be passed into your templates.

    appName: spring-boot-helloworld
    ```
3. Similarly update replicas in the deployment.yaml, with a value called `replicasCount`. In the values file, default replicaCount to 1. 

4. Next update the image name and tag in the template. These two parameters are related, so we will create a nested values. Update the image, line to the following:  
```image: "{{ .Values.image.repository }}:{{ .Values.image.tag}}"```  
The go values are in double quotes intentionally because the **:**, so please use the double quotes.   

5. The values **image.repository** and **image.tag** are commonly used in helm chart world, and an example of using nested values (they should be indented 2 spaces below **image**). In the values.yaml file, these defaults would look like: 
    ```
    appName: spring-boot-helloworld 
    replicaCount: 1

    image:
      repository: spring-boot-helloworld 
      tag: latest
    ...
    ```

6. 


# Additional Documentation/Resources
[Helm - Chart Templating Guide](https://helm.sh/docs/chart_template_guide/getting_started/)  
Go Templates Basic Syntax - still looking for a good resource  
[Go Sprig Package](https://github.com/Masterminds/sprig)  
[Chart Tests](https://helm.sh/docs/topics/chart_tests/) 
[Flat vs Nested Values](https://helm.sh/docs/chart_best_practices/values/#flat-or-nested-values) 