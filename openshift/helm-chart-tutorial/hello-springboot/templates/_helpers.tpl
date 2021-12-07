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