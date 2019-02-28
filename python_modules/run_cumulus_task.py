"""
Interprets incoming messages, passes them to an inner handler, gets the response
and transforms it into an outgoing message, returned by Lambda.
"""
import os
import sys

from cumulus_logger import CumulusLogger
# if the message adapter zip file has been included, put it in the path
# it'll be used instead of the version from the requirements file
if os.path.isfile('cumulus-message-adapter.zip'):
    sys.path.insert(0, 'cumulus-message-adapter.zip')

from message_adapter.message_adapter import message_adapter


def run_cumulus_task(
    task_function,
    cumulus_message,
    context=None,
    schemas=None,
    **taskargs
):
    """
    Interprets incoming messages, passes them to an inner handler, gets the response
    and transforms it into an outgoing message, returned by Lambda.

    Arguments:
        task_function -- Required. The function containing the business logic of the cumulus task
        cumulus_message -- Required. Either a full Cumulus Message or a Cumulus Remote Message
        context -- AWS Lambda context object
        schemas -- Optional. A dict with filepaths of `input`, `config`, and `output` schemas that are relative to the task root directory. 
            All three properties of this dict are optional. If ommitted, the message adapter will look in `/<task_root>/schemas/<schema_type>.json`,
            and if not found there, will be ignored.
        taskargs -- Optional. Additional keyword arguments for the task_function
    """

    context_dict = vars(context) if context else {}
    logger = CumulusLogger()
    logger.setMetadata(cumulus_message, context)
    message_adapter_disabled = os.environ.get('CUMULUS_MESSAGE_ADAPTER_DISABLED')

    if message_adapter_disabled is 'true':
        try:
            return task_function(cumulus_message, context, **taskargs)
        except Exception as exception:
            name = exception.args[0]
            if isinstance(name, str) and 'WorkflowError' in name:
                cumulus_message['payload'] = None
                cumulus_message['exception'] = name
                logger.log({ 'message': 'WorkflowError', 'level': 'error' })
                return cumulus_message
            else:
                logger.log({ 'message': str(exception), 'level': 'error' })
                raise

    adapter = message_adapter(schemas)
    full_event = adapter.loadAndUpdateRemoteEvent(cumulus_message, context_dict)
    nested_event = adapter.loadNestedEvent(full_event, context_dict)
    message_config = nested_event.get('messageConfig', {})

    try:
        task_response = task_function(nested_event, context, **taskargs)
    except Exception as exception:
        name = exception.args[0]
        if isinstance(name, str) and 'WorkflowError' in name:
            cumulus_message['payload'] = None
            cumulus_message['exception'] = name
            logger.log({ "message": "WorkflowError", "level": "error" })
            return cumulus_message
        else:
            logger.log({ "message": str(exception), "level": "error" })
            raise

    return adapter.createNextEvent(task_response, full_event, message_config)
