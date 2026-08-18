# Copyright 2026 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

"""Thin AdkApp subclass that relies on Agent Engine's default telemetry pipeline."""

from __future__ import annotations

import logging

from vertexai.agent_engines import AdkApp

logger = logging.getLogger(__name__)


class InstrumentedAdkApp(AdkApp):
    """AdkApp that uses the default Agent Engine telemetry pipeline.

    The default _default_instrumentor_builder() sets up:
    - TracerProvider with OTLP export to telemetry.googleapis.com/v1/traces
    - GenAI SDK instrumentation
    - Proper resource attributes for Agent Engine dashboard

    ADK already creates semantic spans (execute_tool, tools/call, call_llm)
    for agent operations, so no additional HTTP-level instrumentation is needed.
    """

    def set_up(self):
        # AdkApp.set_up() POSTs to https://telemetry.googleapis.com/v1/traces to
        # warn if the Telemetry API is disabled. With Agent Gateway
        # AGENT_TO_ANYWHERE that probe can RST during TLS; the SDK treats it as
        # a fatal UserCodeControlPlaneError and the engine never serves traffic.
        #
        # The SDK calls a *module-level* `_warn_if_telemetry_api_disabled()`,
        # not `self._warn_if_telemetry_api_disabled()`. Patching only `self`
        # does nothing (confirmed in Agent Engine logs: otel_setup.py:57 ->
        # adk.py:964 -> adk.py:606).
        import vertexai.agent_engines.templates.adk as adk_mod

        def _swallow(fn):
            def _wrapped(*args, **kwargs):
                try:
                    return fn(*args, **kwargs)
                except Exception:
                    logger.warning(
                        "Telemetry API probe failed; continuing Agent Engine startup",
                        exc_info=True,
                    )

            return _wrapped

        orig_mod = getattr(adk_mod, "_warn_if_telemetry_api_disabled", None)
        orig_cls = getattr(AdkApp, "_warn_if_telemetry_api_disabled", None)
        orig_self = getattr(self, "_warn_if_telemetry_api_disabled", None)
        if orig_mod is not None:
            adk_mod._warn_if_telemetry_api_disabled = _swallow(orig_mod)
        if orig_cls is not None:
            AdkApp._warn_if_telemetry_api_disabled = _swallow(orig_cls)
        if orig_self is not None:
            self._warn_if_telemetry_api_disabled = _swallow(orig_self)
        try:
            return super().set_up()
        finally:
            if orig_mod is not None:
                adk_mod._warn_if_telemetry_api_disabled = orig_mod
            if orig_cls is not None:
                AdkApp._warn_if_telemetry_api_disabled = orig_cls
            if orig_self is not None:
                self._warn_if_telemetry_api_disabled = orig_self
