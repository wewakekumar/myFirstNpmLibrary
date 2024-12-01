module.exports = ({github, context}) => {
  const prDescription = context.payload.pull_request.body || "";

  const checked = [];
  const unchecked = [];
  
  const lines = prDescription.split('\n');
  let isChecklist = false;
  for (const line of lines) {
    if (line.includes("Checklist start")) {
      isChecklist = true;
    }
    if (line.includes("Checklist end")) {
      isChecklist = false;
    }
    
    if (isChecklist && line.startsWith('- [x]')) {
      checked.push(line.substring(6).trim());
      core.info(`Found checked box: ${line}`);
    }
    if (isChecklist && line.startsWith('- [ ]') && isChecklist) {
      unchecked.push(line.substring(6).trim());
      core.info(`Found unchecked box: ${line}`);
    }
  }
  core.setOutput('checked', checked.join(','));
  core.setOutput('unchecked', unchecked.join(','));
  return { checked, unchecked };
}

