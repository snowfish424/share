"""Render workshop manifests without requiring envsubst or third party packages."""
import argparse
import json
import re
from pathlib import Path


def validate_image(image):
    # Restrict interpolation to an image reference. A digest or a unique tag is required.
    if not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9._:/@+-]*", image):
        raise ValueError("Image reference contains unsupported characters")
    if "/" not in image or (":" not in image.rsplit("/", 1)[-1] and "@sha256:" not in image):
        raise ValueError("Use a fully qualified image reference with a tag or digest")
    if ".invalid" in image or "YOUR_" in image:
        raise ValueError("Replace example registry values first")


def validate_claim(claim_name):
    if len(claim_name) > 63 or not re.fullmatch(r"[a-z0-9](?:[a-z0-9-]*[a-z0-9])?", claim_name):
        raise ValueError("PVC name must be a valid DNS label")


def render(image, storage="pvc", storage_class=None, claim_name="cwa-weather-data", size="1Gi"):
    validate_image(image)
    validate_claim(claim_name)
    if storage not in ("pvc", "emptydir"):
        raise ValueError("Storage must be pvc or emptydir")
    if not re.fullmatch(r"[1-9][0-9]*(?:Ki|Mi|Gi|Ti)", size):
        raise ValueError("Storage size must be a positive binary quantity, such as 1Gi")
    if storage_class is not None and (len(storage_class) > 253 or not re.fullmatch(r"[a-z0-9][a-z0-9.-]*[a-z0-9]|[a-z0-9]", storage_class)):
        raise ValueError("Invalid StorageClass name")
    result = TEMPLATE.replace("__IMAGE_JSON__", json.dumps(image))
    if storage == "pvc":
        volume = "persistentVolumeClaim:\n            claimName: " + claim_name
        strategy = "type: Recreate"
        class_line = "" if storage_class is None else "  storageClassName: " + json.dumps(storage_class) + "\n"
        pvc = ("apiVersion: v1\nkind: PersistentVolumeClaim\nmetadata:\n"
               "  name: " + claim_name + "\n  labels:\n    workshop: cwa-podman\n"
               "    workshop-data: persistent\nspec:\n  accessModes: [ReadWriteOnce]\n" + class_line +
               "  resources:\n    requests:\n      storage: " + size + "\n---\n")
    else:
        volume = "emptyDir: {}"
        strategy = "type: RollingUpdate\n    rollingUpdate:\n      maxSurge: 1\n      maxUnavailable: 0"
        pvc = ""
    return pvc + result.replace("__STRATEGY__", strategy).replace("__DATA_VOLUME__", volume)


def render_maintenance(image, claim_name="cwa-weather-data"):
    validate_image(image)
    validate_claim(claim_name)
    return """apiVersion: v1
kind: Pod
metadata:
  name: cwa-data-migrate
  labels:
    workshop: cwa-podman
spec:
  serviceAccountName: cwa-app
  automountServiceAccountToken: false
  restartPolicy: Never
  securityContext:
    seccompProfile:
      type: RuntimeDefault
  containers:
    - name: transfer
      image: __IMAGE_JSON__
      command: [python3, -c, "import time; time.sleep(3600)"]
      resources:
        requests: {cpu: 100m, memory: 128Mi}
        limits: {cpu: 200m, memory: 256Mi}
      securityContext:
        runAsNonRoot: true
        allowPrivilegeEscalation: false
        readOnlyRootFilesystem: true
        capabilities:
          drop: [ALL]
      volumeMounts:
        - name: data
          mountPath: /opt/app/data
  volumes:
    - name: data
      persistentVolumeClaim:
        claimName: __CLAIM__
""".replace("__IMAGE_JSON__", json.dumps(image)).replace("__CLAIM__", claim_name)


TEMPLATE = """apiVersion: v1
kind: ConfigMap
metadata:
  name: cwa-weather-config
  labels:
    workshop: cwa-podman
data:
  STATION_NAME: Taipei-DEMO
  APP_MESSAGE: Podman to OpenShift
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: cwa-weather
  labels:
    app: cwa-weather
    workshop: cwa-podman
spec:
  replicas: 1
  revisionHistoryLimit: 5
  progressDeadlineSeconds: 180
  strategy:
    __STRATEGY__
  selector:
    matchLabels:
      app: cwa-weather
  template:
    metadata:
      labels:
        app: cwa-weather
        workshop: cwa-podman
    spec:
      serviceAccountName: cwa-app
      automountServiceAccountToken: false
      securityContext:
        seccompProfile:
          type: RuntimeDefault
      containers:
        - name: api
          image: __IMAGE_JSON__
          imagePullPolicy: Always
          ports:
            - name: http
              containerPort: 8080
          envFrom:
            - configMapRef:
                name: cwa-weather-config
          resources:
            requests:
              cpu: 100m
              memory: 128Mi
            limits:
              cpu: 200m
              memory: 256Mi
          securityContext:
            runAsNonRoot: true
            allowPrivilegeEscalation: false
            readOnlyRootFilesystem: true
            capabilities:
              drop: [ALL]
          startupProbe:
            httpGet:
              path: /healthz
              port: http
            periodSeconds: 2
            failureThreshold: 30
          readinessProbe:
            httpGet:
              path: /readyz
              port: http
            periodSeconds: 5
          livenessProbe:
            httpGet:
              path: /healthz
              port: http
            periodSeconds: 10
          volumeMounts:
            - name: data
              mountPath: /opt/app/data
            - name: tmp
              mountPath: /tmp
      volumes:
        - name: data
          __DATA_VOLUME__
        - name: tmp
          emptyDir: {}
---
apiVersion: v1
kind: Service
metadata:
  name: cwa-weather
  labels:
    workshop: cwa-podman
spec:
  selector:
    app: cwa-weather
  ports:
    - name: http
      port: 80
      targetPort: http
---
apiVersion: route.openshift.io/v1
kind: Route
metadata:
  name: cwa-weather
  labels:
    workshop: cwa-podman
spec:
  to:
    kind: Service
    name: cwa-weather
  port:
    targetPort: http
  tls:
    termination: edge
    insecureEdgeTerminationPolicy: Redirect
"""


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--image", required=True)
    parser.add_argument("--output", default=".generated/app.yaml")
    parser.add_argument("--storage", choices=["pvc", "emptydir"], default="pvc")
    parser.add_argument("--storage-class", help="Omit to use the cluster default StorageClass")
    parser.add_argument("--claim-name", default="cwa-weather-data")
    parser.add_argument("--size", default="1Gi")
    parser.add_argument("--maintenance", action="store_true", help="Render the data-transfer Pod instead of the application")
    args = parser.parse_args()
    try:
        result = render_maintenance(args.image, args.claim_name) if args.maintenance else render(args.image, args.storage, args.storage_class, args.claim_name, args.size)
    except ValueError as exc:
        parser.error(str(exc))
    target = Path(args.output)
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(result, encoding="utf-8")
    print(f"Rendered {target} using image {args.image}")
