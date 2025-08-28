- CRITICAL: whenever you are making changes with the Edit tool, you must first use the Read tool or you will get `Error editing file` errors.
- When you feel that using emojis is appropriate, please use them sparingly.  Too many emojis can make things hard to read.
- When we write scripts, I often prefer to write them using Fish shell.  But I'm fine with plain ol bash scripts.
- When we are creating tasks using `mise`, I will never want to use TOML-based tasks.  You will always use file-based tasks.

Additionally you should reference the documentation to ensure the configuration comments and syntax are used correctly:
- File Tasks: https://mise.jdx.dev/tasks/file-tasks.html
- Task Configuration: https://mise.jdx.dev/tasks/task-configuration.html
- Dynamic Dependencies: https://mise.jdx.dev/tasks/architecture.html#dynamic-dependencies
- Tasks Overview: https://mise.jdx.dev/tasks/
- Environment Variables Passed to Tasks: https://mise.jdx.dev/tasks/#environment-variables-passed-to-tasks
- I prefer using `mise` tasks over Makefiles because `mise` is a lot more portable and easier develop with.