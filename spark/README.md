spark Cookbook
====================
This cookbook set up Spark master and slaves on AWS OpsWorks.

Requirements
------------
TODO: List your cookbook requirements. Be sure to include any requirements this cookbook has on platforms, libraries, other cookbooks, packages, operating systems, etc.

#### platforms
- Ubuntu 12.04 LTS on AWS OpsWorks

#### other cookbooks
- `apt`
- `java`

Attributes
----------
TODO: List your cookbook attributes here.

e.g.
#### spark::default
<table>
  <tr>
    <th>Key</th>
    <th>Type</th>
    <th>Description</th>
    <th>Default</th>
  </tr>
  <tr>
    <td><tt>[:spark][:layershortname]</tt></td>
    <td>String</td>
    <td>Short name of the layer in AWS Opsworks</td>
    <td><tt>spark</tt></td>
  </tr>
</table>

Usage
-----
- Create a layer with `[:spark][:layershortname]` as short name.
- Add `spark::setup` to the Setup lifecycle event.
- Add `spark::configure` to the Configure lifecycle event.
- Add an instance and name it "master".
- Add a few instances named "slave1", "slave2" etc.
- Start the instances.

Contributing
------------
TODO:
- Improve passwordless SSH login setup [SSH]
- Deal with change of master
- Recipe for the Shutdown lifecycle event
- Improve nodes start/stop logic

e.g.
1. Fork the repository on Github
2. Create a named feature branch (like `add_component_x`)
3. Write your change
4. Write tests for your change (if applicable)
5. Run the tests, ensuring they all pass
6. Submit a Pull Request using Github

License and Authors
-------------------
Authors: Li Jin

Copyright 2014, Li Jin

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
