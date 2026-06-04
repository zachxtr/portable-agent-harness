# Policy Command ToDO

## Active Backlog

**BUGS & FIXES:**
  
  - [ ] write script to create the bill tracking log... 
  - [ ] Update SESSIONMEMORY.md to ROLLINGMEMORY.md 
  - [ ] Have the citation grounding work for statutes to NOT source statutes that don't are not in retreval chunks  
  - [ ] Don't display the shared content if it's not available documents, library, chats - I think already works this way
  - [ ] Fix desktop sidebar scrolling issue so they are independant.  issues on the ViewPDF page, StatuteChapter page , Bill Index page, etc
- [ ] WORKSPACE.md - help the assistant know the bill data structures and the statute data - [ ] structures...  Both Matilda and the worker agents would benefit (Bill review and Bill analysis) 
  - [ ] Put the short marketing on the down scroll of the landing page.  Have some kind of animation that encourages people to scroll neon arrow something that has color and excitement movement. 
  - [ ] review and walk through fixes for conv-1780351301785-bygnvmwr7 (desktop for system admin).  JSON parse errors to fix...  
  - [ ] conv-1780382972996-duh97pxrt (desktop for system admin) bad response and there are 5 related bills. 
  - [ ] Implement Platform Guide per `memory/wip_platform_guide_work_plan.md` — auth-only standalone `/platform-guide` (not public); user menu above Sign out; agents maintain 
  - [ ] run backup and restore from desktop to get BillTrackingLog
  - [ ] **document-scraping → indexing-service:** review `publishDocumentEvent` / `POST /index/document` (`eventPublisher.ts`, `INDEXING_DOCUMENT_URL`) — fire-and-forget per scraped file from bill scrapers (versions, analysis, amendments, vote history) and statute `ChapterScraper`; during batch collection this fans out one HTTP call per document and can saturate indexing-service (20 workers, queue depth 1000+); review rate limiting, batching, queue backpressure, and whether collection should defer indexing until scrape completes
  - [ ] Watch indexing-service logs during a collection run to inventory call volume and hot endpoints (include document-scraping trigger volume vs UI-driven calls)
  - [ ] From the policy profile page add a create policy profile brief button that is primary color
  - [ ] Consider having the legislative analysis use a better model
   
  - [ ] have the clean memory button in the UI offer a running report like what I get from joshua that bubbles ends in possible recomendations and a simple "new" message to the user that memory was cleaned... this would basically be a new message for every login potentialy"  this plays in the the rolling memory over sessionmemmory.md. 
  - [ ] move the keycloak auth key outside of the env.template so it is it's own file and not part of git.
markdown later
  - [ ] Have Personalize Assistant message in the inbox IF not done... should be an easy update based on if the persona/
  - [ ] Update realtime sync to be able to run more than one session have it smart enough to cylce through ALL ACTIVE sessions per the DB table now...
  - [ ] we need to make sure the worker agents see what is added and removed on a bill text.  
  - [ ] **Briefs — Tracking Updates card** — summarize **BillTrackingLog movement events** for library + policy-profile bills (not Postgres `updatedAt` or "you saved a bill"). Goal: "were there tracking events for bills you watch?" — see `TrackingUpdatesBriefingService.ts`; compare `TeamActivity` / bill tracking dashboard data sources.
- [ ] **Briefs — Team Updates card** — align activity feed with **`TeamActivity.tsx`**: include policy profile **`update-log/` entries** (`listPolicyProfileUpdateLog`, 90d window, `policy-profile-event` rows) — not profile `createdAt`/`updatedAt` only. Reuse `apps/web/src/utils/policyProfileTeamActivity.ts` helpers or shared storage-client parity in `TeamUpdatesBriefingService.ts`.
  - [ ] Have a history item from the bill tracking dashboard open to the bill history section of the bill details page.  same for other parts of the bill document 
  - [ ] ChatInput has offerChip for “Yes, proceed” on clarify mode — chat page never passes it. Types document this behavior. Wire when you’re in chat polish, not before session refresh.
  - [ ] Prod ECS task role — grant `bedrock:Rerank` for rap-service (rerank 403 fallback today)
  - [ ] Agentic runs with tool calls don't seem to stream 
  - [ ] Review the discovery response_mode and how it uses templates for data assemble (inventory) and llm generate (formmater, summarizer) and if these should be used by the other modes to clean formmating with the LLM... json "contracts" with the LLM call were it "fills in" the provided template...  this can be added as a resource for the SKILL and passed into the worker agent pipeline...
  

---

## Policy Profile

Maybe when you have a ad policy profile button on the policy profile page it opens the chat with a special focus with added start and date and start buttons that are parked of a new section like the chat and statue buttons.  All about it would show the handle of the policy profile that's in focus you can click on it it goes to the policy profile or input a start and end date and it generate when you see it and can export it as a PDF.  That gives me a workflow to align it to a provided template That's one of the things that you could upload with a special button.  Maybe as a drop down so that I can add them on the system side as customized options for an account that would be easier at first

Just realized a policy profile focus lens would only be for the assistant in most cases...  It wouldn't have to be for the worker agent per se consider how it could be working that way and then dump to the worker agents would be dispatched with different instruction based on the policy profile length 

add new dreaming deep check feature for the policy profiles so that every night we run searches of the bills on your keywords and we keep a tracking history json record in a policy-profiles/{policyProfileId}/tracking/ folder in the agent-workspace that has the stripeSubscriptionId and tok count PLUS we display it on the policy profile page as a "nightly tracking report" then update the tracking update brief to just summarize these and not re-run bills that are in the policy profile.  

have this run policy profile brief endpoint that produces output on any movement for a date range? 

Be able to add contacts to a policy profile — name, phone, email, and OTHER socials that we can pull from.

For the added contacts we can set them as an Ally or Opponent. Be able to add a website as an ally or opponent.

Ask assistant from policy profile and have it in focus for backend content — display the short name as "pill" like bill and statute key.  Have an open in assistant button on the policy profile details page. Profile as a context selector — "Working in: Florida Education Policy 2026" — injects associated bills, statutes, keywords.

Outputs: 1) summary report for time period, 2) proposed amendment language, 3) policy brief

Have the ability to add artifacts to the policy profile (index them maybe) and have them be part of the chat and can be source references. Have generated reports stored here as well. 

One-click brief: export profile + all associated bills/statutes

---

## Briefs

For Briefs: "Nothing has changed on your saved bills" as a response.

**Data sets for review**
- chat history
- users nav logs
- bill tracking log
- policy-profiles
- team activity
- 

Should we run analytics on a users chat-history and report that on the Brief?  as past conversations 

So even if it is over 7 days back ALWAYS have the last conversation. Then they know the last conversation could have been like a month ago. So always have the last 1 record for each of the datasets as a "this is the last time this thing happened" baseline. We need to document this in the code as it should be a best practice for LLM interaction between the assistant and user for context.

---

## Policy Assistant Agent Harness

Make sure the assistant knows about the different parts of the system and can help guide you through them... 

Have a suggest button that helps complete identity and soul - use the info that's been added by the user so far and the dropdown values....

Review what should the assistant "load" for the worker agent based on each skill?  documents/artifacts, policy-profile data, summary of past analysis? 

Multi-user chats — assistant has full conversation context to include in asssitant response... who are the team mebmers?

For example: "Hey Monica, can you summarize what we worked on last week?" Have an assistant command of "what did I look at yesterday?" or "what did we work on last 5 sessions? Please summarize this team collaborative brainstorming."

Assistant command for get user activity and get user library.

**Chat page — Memory panel UI:**
- Sidebar/drawer on the chat page for browsing and accessing memory files
- Four sections: `MEMORY.md` (pinned), policy profile notes (grouped by profile name/handle), topic notes (by slug); session history via turn JSON / SESSIONMEMORY index (future)
- Click to open renders the file as markdown inline — read-only view with "Add to context" button to inject into the active conversation
- "Remember this" shortcut on chat message bubbles — highlight or one-click sends the content to the agent as a memory write; agent confirms what it wrote and where
- Badge on memory panel button when there are pending `AgentUpdateProposal` items (ties to management screen Proposals panel)
- Auto-create a `memory/policy-profile-{handle}.md` when a policy profile is opened in chat context for the first time

Heartbeat.md for the assistant — allows the completion of tasks, can see session in the usage history via "tokens" or "energy." Different scheduled tasks will deplete monthly allowance.

Review the eval process Casey had for Lex response.

Concept of reviewing a pdf document and adding TODO: markers for PA agent followup... based on the annotations on the documents the LLM could comment and dig in based on the context and location provide a deaper analysis.

**Response Rating Summary**

Default state: Persistent 👍 / 👎 on every response — inline, always visible, never interrupting workflow.
On 👎 only: Surface 3–4 quick-select pills (using your existing filterPill component) to capture why. Something like:

Too long · Too short · Off topic · Missing context · Wrong tone

Auto-dismiss after selection, no modal, no confirmation step.
On 👍: Silent capture only — no follow-up, no friction.

Why this works for Policy Command:
- The pill pattern already exists in your design system so it'll feel native, not bolted-on. The 👎 + pill combination gives your PA agent's memory manager two data points per negative signal — that it was wrong and how it was wrong — which is exactly what you need to write meaningful preference updates at end-of-turn.

how to use on creating the avatar...

When regenerate for the Avatar picture have a give me direction pop up 


**Memory management & Dreaming**

Dreaming — scheduled consolidate + review-suggestions (same backend as memory tab buttons)

Build out memory management UI beyond consolidate/review — topic memories, index view


---

## RAP Service & Worker Agents (`rap-service`)

**Focus**
- Reivew the value of documentKey in "focus" the same as billKey and statuteKey.  this would setup apprpriations analysis
- How do we add more than one bill?
- Uploading of added files (artifacts): within these files handle redlines with strikethrough and underline.
- 

Have the assistant recommend using newest files to the skill worker agent for initial analysis — i.e. use most recent bill version only. This can be in the details to the `policy-command-bill-review` skill.

Does the temperature for the call to the worker affect the response drastically? If yes THEN this should be controlled by the assistant based on user tone — we should map this directly if impact is big as it is a simple knob to bubble up.

Decide how we want to store artifiacts records in S3. do we have an artifacts/ folder? do we want one?  or put the artifact in the folder it logically is associated to and it becomes a special file name key flag for .json files (__artifact__) so we can find them and distigish them as needed? need to document and support in the agent-workspace definitions and in the WORKSPACE.md file... we have a nice recordKey system for files stored in s3 to leverage here. 

Review and optimize the PA opration tools should be ~ 10 - what do they need?

Decide when to build out Dreaming routines...  


**Worker Agent — Knowledge Base Design**

Do I need a "knowledge base" that is organized notes for each bill, or a pointer to the "current" form of the bill and then a more detailed search including the "stale" parts only if needed?
- How do we make the bill documents that are reviewed most relevant?
- If a bill has 3 versions we should only be initially looking at the latest version
- For MOST questions the amendment documents don't have much value
- Vote documents either
- Nearest neighbor for larger content context?


---

## Bills & Data Collection (`document-scraping-service`)

The realtime sync log is a dataset for bill tracking to pass to the agent to see the lay of the land


Bill Collection, Notifications, Realtime Sync — `pipeline-service`

Rate limit by FL Senate site now during HTTP requests? Can we use different IPs?

Refactor `document-scraping-service`

For new tiered architecture with fan-out workers: we need to add in how the orchestrator fans out for the scraping of each type of bill document, who saves the metadata and collection URL to the database. How do we represent the Fargate spot workers locally? Are they new microservices in Docker containers?

Have the legislators as contacts that are maybe in the `_system` defaults or the `_agent-workspace/` defaults.

Have committee scraping services that add legislators not as DB records but VCF stored in S3 under `_system/contacts/fl/xxx/`.

New committee meeting of interest that you can add to calendar — need a way to let the user display it and have a "cheap" version that does not cost much. Get to the point where the user can configure the dashboard with the cards they want so that it will burn x tokens every time they check (i.e. log out and back in).

Committees and a legislators directory tool — web crawl in real time based on structured URL data. Like an instant crawl.

Add a committee, senator, and representative lookup as tools so that the agents can pull directly from the Florida Senate site, not have to import the data for phone numbers and schedules. Would I be able to create an agent task that would check a committee calendar every 30 minutes and then as soon as it was available schedule it on your calendar?

`POLICY_COMMAND_ARCHITECTURE.md` — needs update

Backup Indexes & Data — TEST!


---

## Indexing & Search (`indexing-service`)

Have the context section of a document as a hierarchical tree — think a TOC with summaries of every node. The company PageIndex uses this with no chunks. Then look at semantic chunks that are organized based on the TOC to get the correct context within the semantic chunk search.

Concept of an index crawler that ADDS contextual value to the chunk — related bills or `billKeys` in the statute for bill references of what bills changed a statute.

Have a "knowledge wiki" as the layer between data and the agents. RAG is dying. As part of the knowledge wiki it can offer "canned" answers to similar questions.

Have a policy guide for appropriations (budget) — will be the first one, see if Casey will help make it. It will add a new route as a setting for an agent with access to a new index and maybe even an API call after getting through and understanding the RAP pipeline.


---

## UI / UX


Statute display as HTML with citation support so that the cited section can be put into scroll focus

---

## Infrastructure & DevOps

Terraform updates: backend split for Policy Command so it can be turned up and down independently from user-facing services (see Active Backlog #6)

IaC scaling — figure out where infrastructure as code can live in the code itself to scale up and scale down automatically based on config values. Have thresholds on budget and urgency so that the system self-scales if budget is available.

`serverless/` folder to hold AWS code needed for realtime processing on AWS.

Consider using the `storage-client` pattern in `models-db-client` to clean up all the duplicative data access calls to PostgreSQL:
```ts
import { UserAgentWorkspaceClient, ConversationWithTurns } from '@policy-command/storage-client';
```

Create README for Stripe product setup and trial codes.

---

## Dream / Autonomous Jobs

Have "dream" process review called skills and evaluate on how well it helped the AI response based on the chat turn record logs… then update.

Have a "dream" routine that collects all the contacts from each user's workspace and adds them at an account level. If we get access to a user's email we can pull in a LOT of contacts and then have "dream" collect data on them.

Dream will create costing tokens saved as a new `__tok123tok___` in a folder in the users profile/ or maybe a new drea/ folder?

Have a "dream" job that runs every night and reviews a user's interactions with the assistant and offers improvements to their persona files that will better align with the user based on past communications. This should be a feature a user can try in beta.

---

## Research & Random Thoughts

> Ideas dump — categorize later when actionable.

- https://www.ibm.com/think/topics/ai-agents-vs-ai-assistants
- https://docs.openclaw.ai/
- https://youtu.be/BMDFPOyezH4?si=0Ej1IdacNu2DgP5V
- https://youtu.be/rSKh6bVuVZI?si=3dzQmidW23VS8Zkc
- A2A example: https://aws.amazon.com/blogs/machine-learning/introducing-agent-to-agent-protocol-support-in-amazon-bedrock-agentcore-runtime/
- Compound Engineering — planning assistant that follows plans to automate office work
- PageIndex — hierarchical document context with no chunks
- Need to emphasize strategy as a service of the platform. It synthesizes and augments the best and brightest of your team.

In the web app, consolidate types from the Api service to the types folders by entity type - like bill, policy-profile, user, then make sure they are use throughout.  

The mobile sheet on the phone blink if there is a need for the user to approve a proposal.  We can have a swipe to the right on the card once it's raised up to have a screen that is like a direct connection to the assistant outside of the chat. the top part of the window is Assistant OR something else like the icon of the section of the app you are in - so Bills, Statutes, Chat, etc that line up with the left menu bar as grounding...

Manual user saves from the UI need to be documented in some form of memory.  Unless they do a nuclear reset but that loses a lot and we should save off an archived copy of all the files in the persona folder with a date so they could restore it

Add "snapshot" consciousness like in book as architecture concept to engage the best experience 

Have a project manager worker that creates an actionable list of steps to complete on looping LLM calls to progress a workflow. Make sure this is tied to the feedback loop of confirmation in the working context — "yes, please" button.


Have the ability to add artifacts (documents) to the team conversation. Attach bills and statutes to it that are relevant — so for a chat there becomes an "Add Bill" or "Add Statute" button that explicitly adds those to the conversation. What are things that could be added? A bill file, a statute, another conversation, a search list, annotated documents?

`tasks/` and `dream/` folders to hold files about these funtionalities?

Plugins I need for website review from claude/Exa/Firecrawl

Claude Plugins (see YouTube history) — website review tools, look at claude/Exa/Firecrawl.

Lookup the Compound Engineering concept to help users have a planning assistant that follows plans to get work done on automating office work.

Change add to policy profile to toggle policy profile

Have the intro to each team tracking and Bill tracking be a hyperlink button the item as an accent color for activities of a fellow user have it open their avatar

Getting the FAQ done we'll harden the product and get it production ready and then that gets baked into the data sets that go into the rolling memory.   

Maybe develop a skill for Matilda where the data set is the FAQ.  Which she then have access to tools to add stuff to the profile and what not she could call the same apis?  

When guides aren't abled you only have one enabled at a time so not to overwhelm the assistant with skills

Have a dark period for real-time scraping 


ROLLINGMEMORY.md

- [ ] **Rolling memory — Zach follow-ups (WIP §Zach thoughts):** compare each Briefs card’s datasets to INTERPRET/tools/skills; plan detailed `memory/*.md` files and UI; after clean `ROLLINGMEMORY.md` prioritize **getting folks using the system** over Platform Guide / deep memory UI

 have a ROLLINGMEMORY.md.  yaml matter will allow me to keep it at a set duration so I can tune how much memory it has.  That way it doesn'That way it doesn't get cut off with web sessions. It's time- similar as you would expect a human to have. And curated as a map back to the different parts of the system so you can pick work back up like what I've started with session memory to password index...   

Rolling memory fills up to a size which we can manage and then it it has a first in last out roll.  track chat histories, policy profiles, bills and statutes, as well as documents.  Just keep a short section on each that's easy to consume and write to

 That is what is then displayed on the memory files.  User can see and edit the rolling memory as well as the long-term memory. Basically it's like your navigation history from a user's experience but conceptually what you did across time with the your assistant.. 

 Have other parts of the system right to agent memory like when you had a policy profile create the memory detail rile.  

 Of that as part of the memory distillation realign the main memory file with current what you're working on


 I don't need to have a folder structure and workspace but I do need to have a link to the platform guide  That will enable my agent to know what the system does and help me get through it!  And remember what I've done in it.  That's my alignment to the system that's what I mean when I say Matilda should know the different parts 


 Have create memory skill.  Basically the introduction of skill files that are internal not just external to work or agent