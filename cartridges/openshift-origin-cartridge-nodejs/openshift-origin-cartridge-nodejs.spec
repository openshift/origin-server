Summary:       Provides Node.js support
 Name:          openshift-origin-cartridge-nodejs
-Version: 1.14.1
+Version: 1.14.1
 Release:       1%{?dist}
 Group:         Development/Languages
 License:       ASL 2.0
@@ -41,15 +41,30 @@ Provides Node.js support to OpenShift. (Cartridge Format V2)
 %__mkdir -p %{buildroot}%{cartridgedir}
 %__cp -r * %{buildroot}%{cartridgedir}
 
+echo "NPM installed Node version is `/usr/local/n/versions/0.10.15/bin/node -v`"
+
 echo "NodeJS version is `/usr/bin/node -v`"
-if [[ $(/usr/bin/node -v) == v0.6* ]]; then
-%__rm -rf %{buildroot}%{cartridgedir}/versions/0.10
-%__mv %{buildroot}%{cartridgedir}/metadata/manifest.yml.0.6 %{buildroot}%{cartridgedir}/metadata/manifest.yml;
-fi
 
-if [[ $(/usr/bin/node -v) == v0.10* ]]; then
-%__rm -rf %{buildroot}%{cartridgedir}/versions/0.6
-%__mv %{buildroot}%{cartridgedir}/metadata/manifest.yml.0.10 %{buildroot}%{cartridgedir}/metadata/manifest.yml;
+if [ -f /usr/local/n/versions/*/bin/node ]; then
+        echo "USING NPM VERSION ON SERVER"
+        if [[ $(/usr/local/n/versions/*/bin/node -v) == v0.6* ]]; then
+                %__rm -rf %{buildroot}%{cartridgedir}/versions/0.10
+                %__mv %{buildroot}%{cartridgedir}/metadata/manifest.yml.0.6 %{buildroot}%{cartridgedir}/metadata/manifest.yml;
+        fi
+        if [[ $(/usr/local/n/versions/*/bin/node -v) == v0.10* ]]; then
+                %__rm -rf %{buildroot}%{cartridgedir}/versions/0.6
+                %__mv %{buildroot}%{cartridgedir}/metadata/manifest.yml.0.10 %{buildroot}%{cartridgedir}/metadata/manifest.yml;
+        fi
+else
+        if [[ $(/usr/bin/node -v) == v0.6* ]]; then
+                %__rm -rf %{buildroot}%{cartridgedir}/versions/0.10
+                %__mv %{buildroot}%{cartridgedir}/metadata/manifest.yml.0.6 %{buildroot}%{cartridgedir}/metadata/manifest.yml;
+        fi
+        if [[ $(/usr/bin/node -v) == v0.10* ]]; then
+                %__rm -rf %{buildroot}%{cartridgedir}/versions/0.6
+                %__mv %{buildroot}%{cartridgedir}/metadata/manifest.yml.0.10 %{buildroot}%{cartridgedir}/metadata/manifest.yml;
+        fi
+        echo "USING NODE VERSION ON SERVER"
 fi
 
 %files
@@ -62,6 +77,33 @@ fi
 %doc %{cartridgedir}/LICENSE
 