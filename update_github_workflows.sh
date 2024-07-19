#!/bin/bash
#
# Copyright 2024 The Bazel Authors. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Utility to properly set up the .github/workflows directory

function update_github_workflows() {
  # Die on errors, unbound variables, and pipe errors
  set -euo pipefail
  local rules_template_dir=$(mktemp -d /tmp/rules-templates.XXXX)
  local rules_android_ndk_dir=$(git rev-parse --show-toplevel)
  local rules_android_ndk_workflows="$rules_android_ndk_dir/.github/workflows"
  mkdir -p "$rules_android_ndk_workflows"
  git clone https://github.com/bazel-contrib/rules-template "$rules_template_dir"
  cd "$rules_template_dir/.github/workflows"
  local rules_template_commit=$(git rev-parse HEAD)

  # For every file in rules-template/.github/workflows, substitute the placeholder
  # 'rules_mylang' for rules_android_ndk and write out the resulting file back to
  # rules_android_ndk/.github/workflows.
  for ci_file in $(ls); do
    if [[ "$ci_file" == "ci.yaml" || "$ci_file" == "buildifier.yaml" ]]; then
      # Don't need ci.yaml or buildifier.yaml for rules_android_ndk, since we've already set up BazelCI.
      continue
    fi
    sed "s/rules_mylang/rules_android_ndk/g" "$ci_file" > "$rules_android_ndk_workflows/$ci_file"
  done
  rm -rf $rules_template_dir

  # Make a commit in rules_android_ndk
  cd "$rules_android_ndk_dir"
  git add .github/workflows
  git commit -m "Pull in github workflows

...from rules-template commit $rules_template_commit"
}

# If this script is invoked from the terminal, call update_github_workflows()
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  update_github_workflows
fi
