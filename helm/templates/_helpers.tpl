{{- define "serviceNameEnv" -}}
{{ printf "%s-%s" $.Values.service.name .Values.environment }}
{{- end -}}

{{- define "version" -}}
{{ $.Values.service.image.tag | default .Chart.AppVersion }}
{{- end -}}

{{- define "imageName" -}}
{{ $.Values.service.image.name | default $.Values.service.name }}
{{- end -}}

{{- define "serviceImage" -}}
{{- if $.Values.service.image.registry -}}
{{ printf "%s/%s:%s" $.Values.service.image.registry (include "imageName" $) (include "version" $) }}
{{- else -}}
{{ printf "%s:%s" $.Values.service.name (include "version" $) }}
{{- end -}}
{{- end -}}
