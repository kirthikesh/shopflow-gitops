{{/*
Image reference for one of our services. Every service in a release runs the
same tag: the git commit the app pipeline built and scanned.
  {{ include "shopflow.image" (list . "order-service") }}
*/}}
{{- define "shopflow.image" -}}
{{- $root := index . 0 -}}
{{- $name := index . 1 -}}
{{- required "image.tag is required" $root.Values.image.tag | printf "%s/shopflow/%s:%s" $root.Values.image.registry $name -}}
{{- end -}}
