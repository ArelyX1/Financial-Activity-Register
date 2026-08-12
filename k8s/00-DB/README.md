First take a look about the server storage
kubectl get pvc -n 2023241041
To restart all DB
kubectl delete deployment lidercom-db -n 2023241041
kubectl delete pvc psql-data-pvc -n 2023241041
Confirm that the storage has been restored
kubectl get pvc -n 2023241041
Apply again the pod
kubectl apply -f psql-local.yaml
Take the pod name
kubectl get pods
Then, restore the backup with:
cat /path/local/lidercom_backup.dump | kubectl exec -i podName -n 2023241041 -c postgres -- pg_restore -U owner -d lidercom -v --no-owner -N "_timescaledb_catalog" -N "_timescaledb_config"
