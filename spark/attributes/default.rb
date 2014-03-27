#
# Cookbook Name:: spark
# Attributes:: spark
#
# Copyright 2014, Li Jin
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# spark-env.sh
default[:spark][:SPARK_MASTER_PORT] = '7077'

default[:spark][:SCALA_HOME] = '/opt/scala-2.10.3'
default[:spark][:SPARK_HOME] = '/opt/spark-0.9.0'
# default[:spark][:SPARK_WORKER_CORES] = '1'
# default[:spark][:SPARK_MEM] = '500m'
# default[:spark][:SPARK_WORKER_MEMORY] = '500m'
# default[:spark][:SPARK_MASTER_MEM] = '500m'
# default[:spark][:HADOOP_HOME] = '"/etc/hadoop"'
# default[:spark][:SPARK_LOCAL_DIR] = '/tmp/spark'
# default[:spark][:JAVA_HOME] = set by java cookbook

##
default[:spark][:layershortname] = 'spark'
default[:spark][:install_dir] = '/opt'
default[:spark][:scala_version] = '2.10.3'
default[:spark][:spark_version] = '0.9.0'

default[:spark][:user] = 'spuser'
default[:spark][:group] = 'spark'
default[:spark][:passwd] = 'password'

# http://docs.aws.amazon.com/opsworks/latest/userguide/workingcookbook-json-override.html
# {
#   "spark" : {
#     "passwd" : "own_password",
#     "password_shadow_hash" : "$?$*",
#   }
# }

