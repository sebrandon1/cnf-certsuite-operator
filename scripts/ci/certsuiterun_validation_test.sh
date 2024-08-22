#!/bin/bash
#
# This script is testing the CertsuiteRun CR validation process.
# Invalid CRs are applied, and it is verified an error is returned.
# Also a valid CR is applied, and it is verified no error is returned.
#

# Bash settings: display (expanded) commands and fast exit on first error.
set -o xtrace
set -o errexit

# Load samples, patching the kustomization.yaml to include the valid configmap and the valid preflight dockerconfig.
make deploy-samples

exit_statuses=()
global_error=0

# Apply/create the valid sample CR.
oc kustomize config/samples | oc apply -f -  && exit_statuses+=(0) || exit_statuses+=($?)

# Invalid configmap names
oc apply -f config/samples/validation-test/invalid_run1.yaml && exit_statuses+=(0) || exit_statuses+=($?)
oc apply -f config/samples/validation-test/invalid_run2.yaml && exit_statuses+=(0) || exit_statuses+=($?)
oc apply -f config/samples/validation-test/invalid_run3.yaml && exit_statuses+=(0) || exit_statuses+=($?)

# Invalid configmaps content
oc apply -f config/samples/validation-test/configmaps/configmap4.yaml
oc apply -f config/samples/validation-test/invalid_run4.yaml && exit_statuses+=(0) || exit_statuses+=($?)
oc apply -f config/samples/validation-test/configmaps/configmap5.yaml
oc apply -f config/samples/validation-test/invalid_run5.yaml && exit_statuses+=(0) || exit_statuses+=($?)

# Invalid preflight secret names
oc apply -f config/samples/validation-test/invalid_run6.yaml && exit_statuses+=(0) || exit_statuses+=($?)
oc apply -f config/samples/validation-test/invalid_run7.yaml && exit_statuses+=(0) || exit_statuses+=($?)

# Invalid preflight secret content
oc apply -f config/samples/validation-test/preflight_secrets/preflight_secret8.yaml
oc apply -f config/samples/validation-test/invalid_run8.yaml && exit_statuses+=(0) || exit_statuses+=($?)
oc apply -f config/samples/validation-test/preflight_secrets/preflight_secret9.yaml
oc apply -f config/samples/validation-test/invalid_run9.yaml && exit_statuses+=(0) || exit_statuses+=($?)

# Invalid log level
oc apply -f config/samples/validation-test/invalid_run10.yaml && exit_statuses+=(0) || exit_statuses+=($?)

# Check valid run CR exit status
if [ "${exit_statuses[0]}" -eq 0 ]; then
    echo "Test passed: valid run sample, has passed validation"
else
    global_error=1
    echo "Error: valid run sample has failed validation"
fi

# Check invalid run CR's exit statuses
for ((i=1; i<${#exit_statuses[@]}; i++)); do
    if [ "${exit_statuses[i]}" -eq 0 ]; then
        global_error=1
        echo "Error: invalid_run$((i)) has passed validation"
    else
        echo "Test passed: invalid_run$((i)), has failed validation"
    fi
done

# Check if any errors occurred
if [ $global_error -eq 1 ]; then
    echo "Error: unexpectable result from one of the tests"
    exit 1
else
    echo "All Tests have passed!"
fi