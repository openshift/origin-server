# Cron cartridge
This cartridge adds periodic job execution functionality to your
OpenShift application.

## Installation
To add this cartridge to your application, you can either:

1. Add it when you create your application
    
    ```
    rhc app create <APP> ruby-1.9 cron
    ```

1. Add it to your existing application
    
    ```
    rhc cartridge add cron -a <APP>
    ```

## Creating a job
The jobs are organized in `.openshift/cron` directory of your application's source.
Depending on how often you would like to execute the job, you place them in
`minutely`, `hourly`, `daily`, `monthly`, `monthly`.

The jobs are executed directly.
If it is a script, use the shebang line to specify the interpreter to execute it.

    #! /bin/bash
    date > $OPENSHIFT_RUBY_LOG_DIR/last_date_cron_ran

### Note
The jobs need to be executable.

    chmod +x .openshift/cron/minutely/awesome_job
    
## Installing the job
Once you have created the job, add it to your application repository, commit and push.

    git add .openshift/cron/minutely/awesome_job
    git commit -m 'Execute bit set for cron job'
    git push

## Execution timing
The jobs are run by the node's `cron` at specified frequency.
The exact timing is not guaranteed.
If this unpredictability is not desirable, you can inspect the date and/or time
when your job runs.

For example, the following `minutely` job would do anything useful only at 12 minutes after the hour.

    #!/bin/bash
    minute=$(date '+%M')
    if [ $minute != 12 ]; then
        exit
    fi
    # rest of the script

## See also
https://www.openshift.com/blogs/getting-started-with-cron-jobs-on-openshift

# Notice of Export Control Law

This software distribution includes cryptographic software that is subject to the U.S. Export Administration Regulations (the "*EAR*") and other U.S. and foreign laws and may not be exported, re-exported or transferred (a) to any country listed in Country Group E:1 in Supplement No. 1 to part 740 of the EAR (currently, Cuba, Iran, North Korea, Sudan & Syria); (b) to any prohibited destination or to any end user who has been prohibited from participating in U.S. export transactions by any federal agency of the U.S. government; or (c) for use in connection with the design, development or production of nuclear, chemical or biological weapons, or rocket systems, space launch vehicles, or sounding rockets, or unmanned air vehicle systems.You may not download this software or technical information if you are located in one of these countries or otherwise subject to these restrictions. You may not provide this software or technical information to individuals or entities located in one of these countries or otherwise subject to these restrictions. You are also responsible for compliance with foreign law requirements applicable to the import, export and use of this software and technical information.
