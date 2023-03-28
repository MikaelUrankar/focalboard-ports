--- server/services/config/config.go.orig	2023-03-20 10:55:17 UTC
+++ server/services/config/config.go
@@ -72,7 +72,7 @@ func ReadConfigFile(configFilePath string) (*Configura
 // ReadConfigFile read the configuration from the filesystem.
 func ReadConfigFile(configFilePath string) (*Configuration, error) {
 	if configFilePath == "" {
-		viper.SetConfigFile("./config.json")
+		viper.SetConfigFile("ETCDIR/config.json")
 	} else {
 		viper.SetConfigFile(configFilePath)
 	}
