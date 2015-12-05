# Jupyter Notebook Python, Scala, Nodejs, Spark

Jupyter Notebook image modified from [Jupyter project](https://github.com/jupyter/docker-stacks), to include only Python 2.7, Scala 2.10, Nodejs 5.1.1, and Spark 1.5.2.

####Note

Nodejs is served via [iJavascript](https://www.npmjs.com/package/ijavascript) and has no interaction with Spark. 

However, you can use try out a simple single node pseudo-map-reduce implementation via [mrcluster](https://www.npmjs.com/package/mrcluster), which comes pre-installed with the image.

## What it Gives You

* Jupyter Notebook 4.0.x
* Conda Python 2.7.x environments
* Scala 2.10.x
* Nodejs 5.1.1
* pyspark, pandas, matplotlib, scipy, seaborn, scikit-learn pre-installed for Python
* Spark 1.5.2 for use in local mode or to connect to a cluster of Spark workers
* Unprivileged user `jovyan` (uid=1000, configurable, see options) in group `users` (gid=100) with ownership over `/home/jovyan` and `/opt/conda`
* [tini](https://github.com/krallin/tini) as the container entrypoint and [start-notebook.sh](../minimal-notebook/start-notebook.sh) as the default command
* Options for HTTPS, password auth, and passwordless `sudo`


## Basic Use

The following command starts a container with the Notebook server listening for HTTP connections on port 8888 without authentication configured.

```
docker run -d -p 8888:8888 hiveoss/jupyter-notebooks:py-scala-node
```

## Using Spark Local Mode

This configuration is nice for using Spark on small, local data.

0. Run the container as shown above.
2. Open a Python 2 notebook.
3. Create a `SparkContext` configured for local mode.

For example, the first few cells in a Python 2 notebook might read:

```python
import pyspark
sc = pyspark.SparkContext('local[*]')

# do something to prove it works
rdd = sc.parallelize(range(1000))
rdd.takeSample(False, 5)
```

### In a Scala Notebook

0. Run the container as shown above.
1. Open a Scala notebook.
2. Use the pre-configured `SparkContext` in variable `sc`.

For example:

```
val rdd = sc.parallelize(0 to 999)
rdd.takeSample(false, 5)
```


### In a Nodejs Notebook

0. Run the container as shown above.
1. Open a Nodejs notebook.
2. Require [mrcluster](https://www.npmjs.com/package/mrcluster)

For example:

```javascript
const mrcluster = require("mrcluster");

// Do a simple unique word count via map reduce
mrcluster.init()
    .file("mockdata_from_mockaroo.csv")	
	// line delimiter is \n 
    .lineDelimiter('\n')
	// each block is 1 Mb 
	.blockSize(1)	
	// 2 mappers 
	.numMappers(2)
	// 3 reducers 
    .numReducers(3)	
	// function to map a line of data to a key-value pair 
    .map(function (line) {
		// tokenize line 
		// select 2nd col and tokenize it again 
		// get the domain or return NA if null 
		// return a key-value pair of format [domain,1] 
        return [line.split(',')[1].split('@')[1] || 'NA', 1];
    })
	// simple reduce function which return a value of 1 
    .reduce(function (a, b) {
        return 1;
    })
	// sum the values of all key-value pairs in the Reducer 
    .post_reduce(function (obj) {
        var res = Object.keys(obj).map(function (key) {
            return obj[key];
        });
		console.log(obj)
        return res.reduce(function (a, b) {
            return a+b;
        });
    })
	// sum the results returned by all the Reducers 
    .aggregate(function (hash_array) {
        console.log("Total: " + hash_array.reduce(function (a, b) {
            return a + b;
        }))
    })
	// start MapReduce job 
    .start();
```

## Notebook Options

You can pass [Jupyter command line options](http://jupyter.readthedocs.org/en/latest/config.html#command-line-arguments) through the [`start-notebook.sh` command](https://github.com/jupyter/docker-stacks/blob/master/minimal-notebook/start-notebook.sh#L15) when launching the container. For example, to set the base URL of the notebook server you might do the following:

```
docker run -d -p 8888:8888 jupyter/pyspark-notebook start-notebook.sh --NotebookApp.base_url=/some/path
```

You can use this same approach to sidestep the `start-notebook.sh` script and run another command entirely. But be aware that this script does the final `su` to the `jovyan` user before running the notebook server, after doing what is necessary for the `NB_USER` and `GRANT_SUDO` features documented below.

## Docker Options

You may customize the execution of the Docker container and the Notebook server it contains with the following optional arguments.

* `-e PASSWORD="YOURPASS"` - Configures Jupyter Notebook to require the given password. Should be conbined with `USE_HTTPS` on untrusted networks.
* `-e USE_HTTPS=yes` - Configures Jupyter Notebook to accept encrypted HTTPS connections. If a `pem` file containing a SSL certificate and key is not found in `/home/jovyan/.ipython/profile_default/security/notebook.pem`, the container will generate a self-signed certificate for you.
* `-e NB_UID=1000` - Specify the uid of the `jovyan` user. Useful to mount host volumes with specific file ownership.
* `-e GRANT_SUDO=yes` - Gives the `jovyan` user passwordless `sudo` capability. Useful for installing OS packages. **You should only enable `sudo` if you trust the user or if the container is running on an isolated host.**
* `-v /some/host/folder/for/work:/home/jovyan/work` - Host mounts the default working directory on the host to preserve work even when the container is destroyed and recreated (e.g., during an upgrade).
* `-v /some/host/folder/for/server.pem:/home/jovyan/.local/share/jupyter/notebook.pem` - Mounts a SSL certificate plus key for `USE_HTTPS`. Useful if you have a real certificate for the domain under which you are running the Notebook server.
* `-p 4040:4040` - Opens the port for the [Spark Monitoring and Instrumentation UI](http://spark.apache.org/docs/latest/monitoring.html). Note every new spark context that is created is put onto an incrementing port (ie. 4040, 4041, 4042, etc.), and it might be necessary to open multiple ports. `docker run -d -p 8888:8888 -p 4040:4040 -p 4041:4041 jupyter/pyspark-notebook`


