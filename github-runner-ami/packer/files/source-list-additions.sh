<<<<<<< HEAD
=======
#!/usr/bin/env bash

>>>>>>> e036ae904379e7364c93a7f23456c3507fb749c9
# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

<<<<<<< HEAD
sudo apt-key add "1646B01B86E50310"
echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
sudo apt-key add /usr/local/sbin/timber.key
echo "deb https://repositories.timber.io/public/vector/deb/ubuntu focal main" | sudo tee /etc/apt/sources.list.d/timber.list
=======
apt-key adv --recv-key 0x1646B01B86E50310 "1646B01B86E50310"
echo "deb https://dl.yarnpkg.com/debian/ stable main" > /etc/apt/sources.list.d/yarn.list
apt-key add /tmp/timber.key
echo "deb https://repositories.timber.io/public/vector/deb/ubuntu focal main" > /etc/apt/sources.list.d/timber.list
>>>>>>> e036ae904379e7364c93a7f23456c3507fb749c9
