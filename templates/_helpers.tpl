{{/*
Expand the name of the chart.
*/}}
{{- define "etcd-cluster.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "etcd-cluster.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- printf "%s" $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "etcd-cluster.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "etcd-cluster.labels" -}}
helm.sh/chart: {{ include "etcd-cluster.chart" . }}
{{ include "etcd-cluster.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "etcd-cluster.selectorLabels" -}}
app.kubernetes.io/name: {{ include "etcd-cluster.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "etcd-cluster.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "etcd-cluster.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{- define "etcd-cluster-certs.admin-common-name" -}}
admin-{{ .Values.clusterDomain | replace "." "-" }}
{{- end -}}

{{/*
Generate TLS CA
Note: Always use this template as follows:
    {{- $_ := include "etcd-cluster.ca.setup" . -}}
The assignment to `$_` is required because we store the generated CI in a global `commonCA`
and `commonCASecretName` variables.

*/}}
{{- define "etcd-cluster.ca.setup" }}
  {{- if not .commonCA -}}
    {{- $ca := "" -}}
    {{- $secretName := "etcd-cluster-ca" -}}
    {{- $crt := .Values.tls.ca.cert -}}
    {{- $key := .Values.tls.ca.key -}}
    {{- if and $crt $key }}
      {{- $ca = buildCustomCert $crt $key -}}
    {{- else }}
      {{- with lookup "v1" "Secret" .Release.Namespace $secretName }}
        {{- $crt := index .data "ca.crt" }}
        {{- $key := index .data "ca.key" }}
        {{- $ca = buildCustomCert $crt $key -}}
      {{- else }}
        {{- $validity := ( .Values.tls.ca.certValidityDuration | int) -}}
        {{- $ca = genCA "ETCD-CLUSTER CA" $validity -}}
      {{- end }}
    {{- end -}}
    {{- $_ := set (set . "commonCA" $ca) "commonCASecretName" $secretName -}}
  {{- end -}}
{{- end -}}