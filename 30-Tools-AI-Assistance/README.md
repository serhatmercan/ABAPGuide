# 30 — Development Tools and AI Assistance

> **Lifecycle:** `CURRENT / RECOMMENDED`. ABAP Development Tools (ADT) are the development environment of every language version; SAP GUI tools remain where Standard ABAP still needs them. AI assistants and MCP servers change quickly: everything in this chapter about them is `VERSION-DEPENDENT` and describes the state observed while this guide was written. See [21-Classic-vs-Modern-ABAP](../21-Classic-vs-Modern-ABAP/README.md).

## 📖 Introduction

The examples in this guide were written, activated and tested with ADT, and part of the verification ran through an AI assistant connected to ADT. This chapter describes those tools from a developer's point of view:

- ADT for Eclipse and ADT for VS Code;
- the SAP GUI tools that still matter in Standard ABAP;
- searching source code across objects;
- ABAP Cleaner and the formatter;
- abapGit;
- what an AI assistant needs to write useful ABAP;
- MCP servers for ADT, the safety model around them, and the limits observed.

Transports and quality gates are the topic of [29-Transport-Quality-Gates](../29-Transport-Quality-Gates/README.md).

## 🧰 ADT for Eclipse

ADT is the Eclipse-based development environment for ABAP. A **project** connects it to one system, client and user; the project tree shows packages, favourites and the objects in them. On-premise, an administrator activates the ICF service `adt` (`default_host` → `sap` → `bc` → `adt` in `SICF`) before ADT can connect, according to SAP's documentation.

The features this guide relies on:

| Task | In ADT | Chapter |
|---|---|---|
| Create, edit, activate | Source editors and form-based editors per object type | all |
| Format | ABAP Formatter with the team's settings ([Rule 12.3](../docs/ABAP-Development-Rules.md#123-format-with-the-abap-formatter-and-the-teams-settings-before-activating)) | [20](../20-Best-Practices/README.md) |
| Find usages | Where-used list | — |
| Run tests | *Run As → ABAP Unit Test* | [22](../22-ABAP-Unit/README.md#-running-the-tests) |
| Check | ATC from the editor or the project | [29](../29-Transport-Quality-Gates/README.md#-atc-checks-variants-and-exemptions) |
| Debug, read short dumps | Debugger, runtime error feed | [23](../23-Debugging-Troubleshooting/README.md) |
| Transports | Transport Organizer view **[verify: features in your ADT version]** | [29](../29-Transport-Quality-Gates/README.md) |

> ⚠️ **Form-based editors can hide state that the object's file does not show.** A lock object created with defaults kept had an empty lock mode, although its file read `exclusive`; the editor showed warnings, the activation did not stop ([27-Lock-Objects](../27-Lock-Objects/README.md#-lock-objects-in-the-abap-dictionary)). After activating a form-based object, check its result, not only the success message.

## 🆚 ADT for VS Code

SAP offers ABAP Development Tools for Visual Studio Code. In the work on this guide it was used to connect an AI assistant to the systems through SAP's ADT MCP server (see below). Which editing, testing and debugging features it offers compared with ADT for Eclipse depends on the version **[verify: the feature set of your ADT for VS Code version]**.

## 🖥️ SAP GUI Tools That Still Matter

In Standard ABAP, some tasks are still done in SAP GUI:

| T-code | Purpose |
|---|---|
| `SE80` | Object Navigator; repository browser and many editors |
| `SE11` | ABAP Dictionary objects not edited in ADT |
| `SE37` | Display and test function modules, including generated ones |
| `SE93` | Transaction codes, for example a report transaction |
| `SE03`, `SE09` | Transport Organizer tools ([29](../29-Transport-Quality-Gates/README.md)) |
| `SREPO` | Repository comparison across systems |
| `CODE_SCANNER` | Source search across programs (see below) |

The SAP BTP ABAP environment has no SAP GUI; its development happens in ADT.

## 🔎 Searching Source Code Across Objects

- **Where-used list** — the first choice when the question is "who calls this?". It follows references, not text.
- **Text search across source code:** in Standard ABAP, transaction `CODE_SCANNER` and the program `RS_ABAP_SOURCE_SCAN` ("Scan ABAP Report Sources") search the source of many objects at once. ADT offers a source search as well **[verify: whether the ABAP source search is available and activated in your system]**.

A text search finds literals, comments and dynamic names that a where-used list misses, and it finds false positives that a where-used list does not. Use both when a change must be complete.

## 🧹 ABAP Cleaner and the Formatter

The ABAP Formatter (the pretty printer in SAP GUI) fixes keyword case and indentation ([Rule 12.3](../docs/ABAP-Development-Rules.md#123-format-with-the-abap-formatter-and-the-teams-settings-before-activating)). [ABAP Cleaner](https://github.com/SAP/abap-cleaner), an open-source tool maintained by SAP, goes further: it applies many configurable cleanup rules in one step, in ADT or as a stand-alone application.

- Share one profile in the team, aligned with sections 3, 4 and 12 of the rules, so that a cleanup does not undo another developer's style.
- In large legacy objects, clean only the lines you change, or clean the whole object in a separate transport, as Rule 12.3 says for formatting.
- Review what the cleaner changed before activating; it rewrites code.

## 🌿 abapGit

[abapGit](https://github.com/abapGit/abapGit) is an open-source Git client that runs inside an ABAP system. It serializes repository objects into files and back, so that ABAP code can live in a Git repository.

It is used to:

- share and install open-source ABAP projects, for example the projects linked in this guide;
- give offline tools such as abaplint complete, serialized objects ([29](../29-Transport-Quality-Gates/README.md#-abaplint-and-continuous-integration), [Rule 13.4](../docs/ABAP-Development-Rules.md#134-use-abaplint-for-offline-checks-of-complete-abapgit-serialized-objects));
- move code between systems that share no transport route, where the landscape allows it.

In a productive landscape, abapGit does not replace the Change and Transport System: what reaches production still travels as a transport request and passes the quality gates.

## 🤖 What an AI Assistant Needs

An AI coding assistant writes plausible ABAP quickly, including names and APIs that do not exist. What it produces depends on what it is told. It needs:

- **The rule set, cited by number.** A context file in the repository points to the rules instead of paraphrasing them ([Rule 15.1](../docs/ABAP-Development-Rules.md#151-cite-these-rules-by-number-in-claudemd-and-similar-instruction-files)). Assistants read such files under different names, for example `CLAUDE.md` or `AGENTS.md`; the name depends on the assistant.
- **The target language version** in every prompt that asks for code ([Rule 15.3](../docs/ABAP-Development-Rules.md#153-state-the-target-language-version-in-every-prompt-that-asks-for-code)).
- **A request to list what it did not verify** ([Rule 15.4](../docs/ABAP-Development-Rules.md#154-ask-the-assistant-to-list-what-it-did-not-verify)).
- **No customer data** in any prompt ([Rule 15.5](../docs/ABAP-Development-Rules.md#155-never-paste-customer-data-into-a-prompt)).

Its output is reviewed against the checklist of [Rule 15.2](../docs/ABAP-Development-Rules.md#152-review-generated-abap-against-this-checklist-before-accepting-it) like any other code.

**Example X1 — a context file for an ABAP repository.**

> 📝 **Configuration example** — an excerpt; the file name depends on the assistant.

```markdown
# Working rules for this repository

- Coding rules: docs/ABAP-Development-Rules.md. Cite rules by number (Rule 2.6).
- Target: ABAP for Cloud Development unless a task says Standard ABAP (Rule 1.4).
- Placeholder namespace zsm; object names per Rule 2.6.
- Reusable units never COMMIT WORK (Rule 7.10).
- Use only the development system named in the task, and only local objects.
- Finish every task with a list of what you did not verify (Rule 15.4).
```

## 🔌 MCP Servers for ADT

The Model Context Protocol (MCP) lets an assistant call tools that another program provides. An **MCP server for ADT** offers tools that act on an ABAP system through ADT: search, read, create, edit, check, activate, run unit tests, run ATC, read feeds such as runtime errors, and, depending on the server, work with transports or generators.

- **SAP's ADT MCP server** is part of ADT for VS Code. In the setup used for this guide, it ran locally while VS Code was running, the assistant connected to it with a token, and an access-restriction preference in ADT decided which destinations it could use; calls to a destination that was not allowed were refused **[verify: how the server is enabled and configured in your version]**.
- **Community MCP servers** for ABAP exist as well. They differ in scope, maturity and maintenance, and this guide does not name or recommend one. The safety model below applies to every server.

What a server can do is listed by its tools. In the setup used for this guide, the tools fell into families: read-only (search, read files and symbols, list creatable types, read feeds, ATC results), writing within an object (create, edit, activate), running code (unit tests), and writing beyond an object (transport requests, generators, ATC quick fixes and AI fixes, exemption requests, actions such as publishing a service). The last family deserves a deny list.

## 🛡️ The Safety Model

An assistant connected to a system can do what its user can do there, quickly and repeatedly. The safety model keeps that within a sandbox ([Rule 15.6](../docs/ABAP-Development-Rules.md#156-connect-an-assistant-only-to-your-own-sandbox-and-restrict-what-it-may-write)):

1. **Own development or sandbox systems only.** Never a customer system, never production, never a system whose data you may not show to the assistant's provider.
2. **Local objects.** Test objects are created as local objects or in a local package, with `zsm` placeholder names; no transport request is created or released by the assistant.
3. **Server-side restrictions.** Allow only the destinations (and, where the server supports it, the packages) the task needs, in the server's own settings.
4. **A deny list on the assistant's side** for tools that write beyond the object being worked on.
5. **Tokens and connection details outside the repository.** They live in local, ignored settings or in the tool's own store ([Rule 8.5](../docs/ABAP-Development-Rules.md#85-never-hard-code-credentials-hosts-or-destinations)); reports and commits never contain system IDs, clients, users or hosts.
6. **No automatic error reporting** that sends prompts, code or system responses to a third party without review.
7. **No customer data in prompts** ([Rule 15.5](../docs/ABAP-Development-Rules.md#155-never-paste-customer-data-into-a-prompt)).

**Example X2 — a deny list for one assistant.**

> 📝 **Configuration example** — for Claude Code; other assistants have their own format. Tool names depend on the MCP server and its version: here, a server registered as `adt`. `VERSION-DEPENDENT`.

```json
{
  "permissions": {
    "deny": [
      "mcp__adt__abap_transport_create_request",
      "mcp__adt__abap_objects_generator_run",
      "mcp__adt__abap_atc_quickfixes_apply",
      "mcp__adt__abap_atc_ai_start_fix",
      "mcp__adt__abap_atc_exemption_request",
      "mcp__adt__abap_object_run_action"
    ]
  }
}
```

**The general principle:** a deny list blocks writing tools **by name**. It cannot say "allow creating objects, but only in `$TMP`". According to Claude Code's documentation, permission rules for MCP tools match the server and tool name, and allow rules cannot match arguments; a check of the arguments, such as the target package or the transport request, needs a separate mechanism, for example a hook that inspects the tool input before the call and blocks it. Other assistants offer different mechanisms; check what yours provides.

## ⚠️ Limits Observed in This Guide's Work

> ⚠️ **VERSION-DEPENDENT: observed tool behaviour.** The following was observed with one ADT MCP server and one assistant while this guide was written. Later versions may behave differently; check your own setup.

- **No editor warnings.** Activation and the check tool returned only "successful" or the errors; warnings that the ADT editor shows for the same object were not returned.
- **The lock-mode trap.** A lock object created through the server had an empty lock mode, although its file read `exclusive`; it activated without messages, and its generated modules locked nothing ([27-Lock-Objects](../27-Lock-Objects/README.md#-lock-objects-in-the-abap-dictionary)). Only reading the generated module showed the problem.
- **No delete tool.** Test objects had to be deleted by hand in the IDE.
- **No console run.** A class implementing `IF_OO_ADT_CLASSRUN` could not be run through the server; the server reported that classes support no actions in this flow. ABAP Unit was the only way to run code.
- **Local objects in the cloud.** In the SAP BTP ABAP environment, creating an object in `$TMP` was refused for lack of authorization; a package below `ZLOCAL` was used instead.
- **Inactive versus active.** Reading the inactive version of an object returned the active text when no inactive version existed, without saying so.
- **Generated modules are not always reachable.** Generated function modules (lock modules, form modules) could be read in one system and not found in the other.

What follows from these limits: treat a tool's success message as a claim and read back the result before recording anything as verified ([Rule 15.7](../docs/ABAP-Development-Rules.md#157-treat-a-tools-success-message-as-a-claim-read-back-the-result), [Rule 13.5](../docs/ABAP-Development-Rules.md#135-claim-a-check-in-the-guides-only-after-it-ran-and-record-it)).

## 🧭 Scope Note

Not covered in this chapter:

- **Installing and configuring** Eclipse, VS Code, ADT or an MCP server step by step; SAP's documentation for your version is the source.
- **SAP Business Application Studio** and the UI tools of Fiori development.
- **Choosing an AI assistant or model**, and prompt techniques beyond the rules of section 15.
- **Building an MCP server.**

## ✅ Best Practices

- Develop in ADT; use SAP GUI tools where Standard ABAP still needs them.
- Use the where-used list first and a text search second when a change must be complete.
- Share one formatter and ABAP Cleaner profile in the team, and review what they change.
- Use abapGit for open-source code and offline checks, not as a replacement for transports.
- Give an assistant the rule set, the target language version and a request for unverified items.
- Connect assistants only to your own sandbox, with server-side restrictions and a deny list.
- Read back the result of every tool call that matters.

## ⚠️ Common Mistakes

- Trusting "Activation successful" for a form-based object without checking its result.
- Connecting an assistant to a customer or production system, or to a system with real business data.
- Allowing an assistant to create or release transport requests.
- Committing tokens, system IDs or users in context files, settings or reports.
- Assuming a deny list can restrict arguments such as the target package.
- Pasting customer code or data into a prompt.
- Copying a community tool's configuration without reading what its tools can write.

## 🎤 Interview & Review Checkpoints

- What does an ADT project connect to, and what must be active on-premise for ADT to work?
- When do you use a where-used list, and when a text search?
- What is the difference between the ABAP Formatter and ABAP Cleaner?
- What is abapGit for, and why does it not replace transports?
- What does an AI assistant need to produce ABAP that follows the team's rules?
- Which tools of an MCP server for ADT would you deny, and why?
- Why can a deny list not restrict a tool to `$TMP`, and what can?
- Name two limits of tool feedback that make reading back the result necessary.

## 🖥️ Related Transaction Codes

| T-code | Purpose |
|---|---|
| `SE80` | Object Navigator |
| `SE11` | ABAP Dictionary |
| `SE37` | Function Builder |
| `SE93` | Transaction codes |
| `SREPO` | Repository comparison |
| `CODE_SCANNER` | ABAP source search |
| `SICF` | ICF services, including `adt` |

## 🔗 Related Chapters

- [29-Transport-Quality-Gates](../29-Transport-Quality-Gates/README.md) — the previous chapter: transports, ATC and abaplint
- [20-Best-Practices](../20-Best-Practices/README.md) — formatting and the review checklist
- [22-ABAP-Unit](../22-ABAP-Unit/README.md) — running tests in ADT
- [23-Debugging-Troubleshooting](../23-Debugging-Troubleshooting/README.md) — the debugger and short dumps in ADT
- [27-Lock-Objects](../27-Lock-Objects/README.md) — the lock-mode finding behind Rule 15.7
- [21-Classic-vs-Modern-ABAP](../21-Classic-vs-Modern-ABAP/README.md) — language versions and released APIs
