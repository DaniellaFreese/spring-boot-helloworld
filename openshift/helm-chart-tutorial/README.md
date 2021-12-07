# Helm Chart Tutorial 

In this guide we will walk through the basics of build a helm chart from scratch with Helm 3. 

The pre-requisistes for this tutorial: 
1. Access to an openshift cluster 
2. Helm 3 cli tool - available in the openshift command line tools 
3. A decent yaml editor - Atom, Sublime, VSCode 


In this tutorial we will review the following: 
* Basic Chart syntax 
* Flat vs Nest Values 
* Flow Control examples 
  * scope
  * if/else 
* Creating and Using a Partial in _helpers.tpl 
  

The output of this tutorial will be a helm-chart of this helloworld springboot application that successfully runs on an openshift cluster. 

## Helm Templating Language
Helm is a packaging and templating engine for Kubernetes. In the background, it is using the Go templating engine and [Go Sprig Package](https://github.com/Masterminds/sprig) (template functions for Go templates) for building charts. In translation what does that really mean? The helm documentation actually provides a nice summary: 

**While we talk about the "Helm template language" as if it is Helm-specific, it is actually a combination of the Go template language, some extra functions, and a variety of wrappers to expose certain objects to the templates. Many resources on Go templates may be helpful as you learn about templating.**

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
   
2. **templates/ :** **Required**
   * **various templates :** **Required** Every yaml file found in this folder is a go-template. Helm will be pick up any yaml files in this directly, and process it when you install/upgrade the helm chart on the cluster. 
   * **_helpers.tpl :** **Optional** A place to put template helpers that you can re-use throughout the chart
   * **tests/ :** **Optional** tests that validate that the chart works as expected when it is installed
3. **charts/ :**  **Optional** A directory containing any charts upon which this chart depends
4. **values.yaml :** The default configuration values for this chart, that later is duplicated per env. 
5. **NOTES.txt :** **Optional** This is a templated, plaintext file that is printed after the chart is successfully deployed. It's great place to describe the next steps for using a chart once it's deployed. 


## How to Test the Chart 
We want to be able to test our chart as we build and customize it. First connect to your cluster via the command line. Once logged in to test the chart, we will be running the following command:  
`helm install test-chart hello-springboot/ --dry-run --debug -f hello-springboot/values.yaml`

## Customizing the Helm Chart 
Now that we've quickly reviewed all the files/directories. Lets's go ahead and blow away everything in the templates directory and start from scratch.  
`rm -r templates/* && rm values.yaml`

We will templatize the resources in the `openshift/app/ directory`, skipping over the buildconfigs. Copy `app/deployment.yaml` and `app/svc.yaml` to the templates directory. 

### Templatize Deployment.yaml 
#### The Basics
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

#### Flat vs Nested Values 
1. Next update the image name and tag in the template. These two parameters are related, so we will create a nested values. Update the image, line to the following:  
```image: "{{ .Values.image.repository }}:{{ .Values.image.tag}}"```  
The go values are in double quotes intentionally because the **:**, so please use the double quotes.   

2. The values **image.repository** and **image.tag** are commonly used in helm chart world, and an example of using nested values (they should be indented 2 spaces below **image**). In the values.yaml file, these defaults would look like: 
    ```
    appName: spring-boot-helloworld 
    replicaCount: 1

    image:
      repository: spring-boot-helloworld 
      tag: latest
    ...
    ```
#### Flow Control- Scope Restriction
Go templates/helm there are options to use if/else statements, loops, and scope restrictions. We need to use some features in flow control to add some annotations to the deployment. 


1. Use scope restriction, keyword `with`, to add the podAnnotations. In the deployment.yaml that will look like: 
```
  template:
    metadata:
      labels:
        app: {{ .Values.appName }}
        version: v1
    {{- with .Values.podAnnotations }}
      annotations:
        {{- toYaml . | nindent 8 }}
    {{ end }}
```
To translate the with statement above, it is saying: with the podAnnotations map defined in the values file, convert to yaml (toYaml function), and add each element to the deployment yaml, and indent each element 8 spaces with a new line (nindent function). 

2. In the values.yaml file add the following: 
```
...
#default podAnnotations example 
#podAnnotations: {}
podAnnotations:
  alpha.image.policy.openshift.io/resolve-names: '*'
  example: hello-annotation 
...
```

*For more examples on flow control (if/else, or loops), take a look at the link in the Additional Documentation section.*

#### Named Templates/Partials in _helpers.tpl  
Following the Helm chart documentation, a *named template* also called *partial* or a *subtemplate* is simply a template defined inside of a file. The _helpers.tpl file is the typical location to store all the partials. 

1. Create an empty templates/_helpers.tpl file: `touch _helpers.tpl`

2. Define a partial for all common labels in the _helpers.tpl, with the following example below: 
```
    {{/*Common labels*/}}
    {{- define "helloworld-springboot.labels" -}}
    {{- if .Chart.Name }}
    helm.sh/chart: {{ .Chart.Name }}
    {{- end }}
    app: {{ .Values.appName }}
    {{- if .Chart.AppVersion }}
    version: {{ .Chart.AppVersion | quote }}
    {{- end }}
    {{- end }}
```
Above we created a partial called helloworld.springboot.labels. It's using if/else flow control and *Built-in Objects* `.Chart.Name`, and `.Chart.AppVersion` from the Chart.yaml itself. If those attribute are defined, then when the partial is executed they will be added to the labels.  

*There are several Built-in Objects* avaiable in helm, check out the link in the Additional Documentation section.* 

3. Reference the partial in the deployment yaml, in the main metadata section, and the spec template section, as shown below: 
```
metadata:
  name: {{ .Values.appName }}
  labels:
    {{- include "helloworld-springboot.labels" . | nindent 4 }}
```
```
spec
  ...
  template:
    metadata:
      labels:
        {{- include "helloworld-springboot.labels" . | nindent 8 }}
```

4. Validate and review through the final output with: `helm install test-chart hello-springboot/ --dry-run --debug -f hello-springboot/values.yaml`


### Ready to Deploy 
You're now ready to deploy the app using helm on openshift. Create a project on OCP, and run the following command: `helm install test-chart hello-springboot/ -f hello-springboot/values.yaml --create-namespace -n <project-name>`

### On Your Own - Templatize svc.yaml 
As an activity, go ahead and property templatize the svc.yaml such that, the svc name, labels, and selector are properly abstracted away from the template. 

## Upcoming in the Next Tutorial! 
We we will cover: 
- writing Chart Tests
- writing a NOTES.txt

# Additional Documentation/Resources
[Helm - Chart Templating Guide](https://helm.sh/docs/chart_template_guide/getting_started/)   
[Go Sprig Package](https://github.com/Masterminds/sprig)  
[Chart Tests](https://helm.sh/docs/topics/chart_tests/) 
[Flat vs Nested Values](https://helm.sh/docs/chart_best_practices/values/#flat-or-nested-values)  
[Named Templates / Partials](https://helm.sh/docs/chart_template_guide/named_templates/)  
[Built-In Objects](https://helm.sh/docs/chart_template_guide/builtin_objects/)    