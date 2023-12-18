 commit_message=$(git log --format=%B -n 1 $COMMIT_SHA)
if [[ $commit_message == *"build@"* ]]; then
    docker_image=${commit_message##*build@}
    docker_image=${docker_image%%[[:space:]]*}
    if [ -z "$docker_image" ]; then
    echo "Error: Invalid commit message format. Unable to extract Docker image name."
    echo "commit message should be: 'build@[image-name:tag]'"
    exit 1
    fi
for folder in $(ls -d images/*); do
    folder_name=$(basename $folder)
    if [ "$folder_name" == "$docker_image" ]; then
    export docker_folder=$folder_name
    echo "Found docker folder:"
    echo $docker_folder
    env | grep "^docker_" > /workspace/build_vars
    exit 0
    fi
done
echo "Error: No matching folder found for Docker image '$docker_image'."
exit 1
fi