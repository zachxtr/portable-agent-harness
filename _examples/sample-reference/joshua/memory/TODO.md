---
todo:
  updated: 2026-07-22
  tiers:
    - active_backlog       # actionable - [ ] items; no bold inside item text
    - domain_concepts      # ## sections — product/engineering notes by area
    - potential            # themes materializing from ideas dump; promote to WIP when scoped
    - ideas_dump           # raw capture — plain lines, blank line between each thought
---

# My Core Imagination TODO

## Active Backlog

- [ ] update the mobile action sheet: remove the assistant action bar display on the Companion pannle  and have the companions avatar over the icon on the top and have the title bar a little taller so the avatar is big enough
- [ ] just like the Guide can creaet an adventure... the MCI Server (platfrom) can create an agent Guide based on the USER.md and What they type in the "what are you looking for? Favorite charater?, Favoriate polit line? Other? prompt...
- [ ] New Adventure from a book or a companion.  if the book is set then have MCI create a Guide based on the USER.md and "Favoriate charater, thing, or concept from the book to *seed* the companion". if the companion is set then assume they are the guide and select a book to start   
- [ ] review Goggle SSO on the registration process and then the signin process.  make sure that there is not auto withoung registering 
- [ ] have new landing for MyCoreTruths.com 
- [ ] verify account creation works with demo and live accounts and get stripe wired for both
- [ ] update the book cover backgournd styles to be what milly and I had.
- [ ] Review what is "saved" as team activity and how it is retrieved and where - if an agent creates another companion that should be logged in Team Activity.  the creator of that companion was Charlette no another user.  the creator of that quest was Dobby.  or it was a user. 
- [ ]  for the companion create have a model selction for the LLM that is "brain" this should be easy to add and just a new paramater to the ai client on which model to use on the call.  
- [ ] clean up the browser stores for MCI
- [ ] count in catalog
- [ ] Create a "Teammates/" folder in the contacts/ folder and move all teamate stuff there, for Policy Command we will have other contact types
- [ ] Move the companions/ folder to contacts/Companions/  this will fit pulling in other contact types that we can pull into an LLM pipeline based on their IDENTIY.md and other files
- [ ] have **study** mode (Assistant, Guide, Study???) where your companion answers questions and offers perspectives of your annotations on a book - **annotations tool** back and forth between the assisant and user ON a document file (pdf, epub, ?) or doucmentTypes that we don't have a tool to work with that aligns the user and the agent on updating the same file in a controled way.  
- [ ] have the background of the book be the background of the chat window when in focus.  if more that one book stack.  
- [ ] a layored avatar?  think book cover. OR let the user upload three images for THERE avatar!!! that is easier and what we will do a simple user avatar builder :-) the only differce is the USER is the Charater and we need a few need layouts 
- [ ] Once a book is in focus make sure that retrieval via RAP is limited to the scope of the book (or active focus context)
- [ ] go through the 3 skills and make sure they align for books so corpus serch and the a book focus only search 
- [ ] The Home and Adventures open on click needs to be able to expand down without the page
- [ ] GuideActionBar like AssitantAgionBar but different... 
- [ ] Have the profile/TokenUsageHistory page talk about MCI Servers **powering** the mana for Companions, Guides, and other agent services.  it takes tokens to power the MCI Servers. Tokens power the MCI Servers to supply mana and mana gives energy to the agents.
- [ ] MAKE sure crating MCI buckets DOES NOT delete the Policy Command ones!!!!!
- [ ] the profile page cards should work like the ones in policy profile with collapse/expand top
- [ ] upload open source songs as a new format for items in the catalog. create a cover and have a music.json record and folder with artistSlug/songSlug/formatSlug as musicKey how do I rag a song?
- [ ] Add File on the Agent Action Card Focus area, have books in focus and quest in focus 
- [ ] Nav History by session
- [ ] have a Add File on the Catalog 
- [ ] upload contracts for review! wills all types of files! shit  this has real value for instant file help from your companion.  uploading a divorce agaeement is an all new kind of chose your own adventure LoL
- [ ] have each users annotations display in their accent color.  
- [ ] support upload of .docx files so writers can upload their own personal stuff to have fun with :-)
- [ ] have the ability to have the companion answer notes that you leave in the book...  
- [ ] review Terms and Privacy Copy to have all that is needed
- [ ] have it easy to get a word defined as an annotation slection
- [ ] have a digital 2d QR code on a companion to download them or open them in your account...
- [ ] quick view nav links to each card for long pages like the companion edit and users profile etc


---

## Code Conversion & Stripe

> indexing-service conversion → `memory/.archive/wip_book-per-source-indexing.md` ✅  
> **EPUB reader + preprocess** → `memory/.archive/wip_epub-reader-html-preprocess.md` ✅  
> web app conversion → `memory/wip_web-app-mci.md` (**cleanup** — Phase 3 strip leftovers)  
> **chat + companion + quest + QG** → Active Backlog below · Adventures Phase A shipped (`memory/SHIPPED_MILESTONES.md`)


**companion bar** (AssistantActionBar inbox/focus)
> MobileActionSheet: have **Quest** mode for focus?
Focus "content" section = Quest mode so that section shows objective and answer input with a Submit button.  If timmed that is where it is disaplyed the linkPill can show the timer in the companion bar.  if no quest in focus still have the section so users understand the format.

books in focus
chats in focus

## My Core Imagination storage structure

**mci-document Bucket** (see `layout/catalog.ts` — canonical)
books/{authorSlug}/{titleSlug}/
- book.json, coverImage.jpg, …
books/{authorSlug}/adventures/{uuid}/adventure.json
books/{authorSlug}/companions/{name}/companion.json

**mci-agents Bucket** (see layout/ — canonical)
accounts/{accountId}/users/{userId}/
- workspace.json 
- user-profile/ settings and persona files (avatar-{userId}.jpg, profile-{userId}.json, USER.md, WORKSPACE.md, MEMORY.md) 
- chat-history/{chatHistoryId}__{dt}.json  ← ChatHistoryDocument (root)
- chat-history/{chatHistoryId}/
  - {dt}__{chatHistoryId}__{traceId}__stripe{id}stripe__tok{n}tok.json  ← turn record
  - {dt}__{chatHistoryId}__{traceId}__{role}.txt  ← optional session logs
- adventures/{uuid}/adventure.json  (public | _private/{uuid} | _deleted/{uuid})
- quest-history/{questHistoryId}__{adventureUuid}__{dt}.json  ← QuestHistoryDocument (root)
- quest-history/{questHistoryId}/
  - {dt}__{questHistoryId}__seq{n}__{traceId}__tok{n}tok.json  ← ObjectiveAnswerRecord
  - {dt}__{questHistoryId}__{traceId}__{role}.txt  ← optional session logs
- library/
- annotations/
- inbox/
- agent-profiles/{agentId}/ config.json, avatar, IDENTITY.md, SOUL.md, MEMORY.md, setup/ — activeAgentKey on workspace.json; RAP `/rap/assistants`; UI says Companion

**Agent tools (mirror UI list/get):** list_adventures, get_adventure, list_quest_history, get_quest_history, list_chat_history, get_chat_history

---

## Potential new functionality

### docx viewer and reader
Alignment of tool and agent writeHistoryId/write-history paralell to quest-history and chat-history

imaging the user uploaded a word file and selecting the type as short story and via a docxViewer a back and forth of editing the file in "writeTurns" - realizing this is a NEW pipeline to build out which is the "mode" of the LLM interaction.  imagine a compose menu option (like Chat) where you have a New doc button that starts a blank docx file (future: md file, txt file (other supported types - spread sheets, diagraming tool, etc) or you start from a docx file the user uploads.  we can leverage the same assistant role persona for the UI/UX but allow them to map calls to the writer mode pipeline.  


(future) rap/write/assistant/ (demonstrats rap/{mode}/{role}/) concept.  for docx flow


### Platform Guide 

funtionality on a page have agent instructions that tie to the tool calls gives both the user AND the agent undersanding of how to use the platform as it is the SAME dataset
example of list

__so get adventure needs to return all the details of the adventure including the associated quest objectives.  I am realizing we should create a separate get quest history tool as well and we can solidify that we have a @.agents/joshua/memory/TODO.md:76-88  quest-history/ folder at the root of the user agent-workspace and that we need to have the fileName of the questHistory JSON file be {DATETIME}__{adventureUuid }__{questHistoryId}.json .  then we can easily pull either all quest history items from a folder OR we can group them or only pull by adventure Uuid.  so actually we need the get aventure to return a list of adventures of nothing is passed and the details of a spcific adventure if the adventure UUID is pased.  get quest history should be the same (and get chat history if not already)  where if you pass a questHistoryId then it returns the details of that item or if nothing is passed a list of the users quest historys.  this one might need criteria like last 10 most recent and then more as well as an adventureUuid.  Have as separate tool calls so list_adventures, get_adventure, list_quest_history, get_quest_history, list_chat_history, get_chat_history.  then the tools will match what we call on the UI side to disaply the same stuff to the user.__

### Adventure Master Agent

Adventure Master = Dungeon Master = DM

The Adventure Master agent is a low cost LLM that basically runs the quest.  it is the DM for that session of gameplay within an Adventure.  

can we have the game structure done without the DM?  Then once a DM is introduced as another LLM charater to drive the quest they show up... well how?

**FUTURE DM bar**
similar color highlight vs of the AssistantActionBar (update name to AgentActionBar)
that will be at the bottom above or below the users companion bar and a system color
the DM can be designed by the uers or can be part of an adventure quest play.  


### Book RAG processing

how to RAG a book - chunk size, extraction, metadata


### Response rating on assistant replies

have it as 5 emojis so laughing face, crying face, etc...

Only ask for more info on dislike as the user will be in a mood to be criticall.  we don't HAVE to take the feedback :-)  

Default state: Persistent 👍 / 👎 on every response — inline, always visible, never interrupting workflow.

On 👎 only: Surface 3–4 quick-select pills (using your existing filterPill component) to capture why. Something like: Too long · Too short · Off topic · Missing context · Wrong tone.

Auto-dismiss after selection, no modal, no confirmation step.

On 👍: Silent capture only — no follow-up, no friction.

The pill pattern already exists in your design system. The 👎 + pill combination gives the Agent's memory manager two data points per negative signal — that it was wrong and how it was wrong — which supports meaningful preference updates at end-of-turn.

### Dream / autonomous memory clean jobs

Have "dream" process review called skills and evaluate on how well it helped the AI response based on the chat turn record logs… then update.

Have a "dream" routine that collects all the contacts from each user's workspace and adds them at an account level. If we get access to a user's email we can pull in a LOT of contacts and then have "dream" collect data on them.

Dream will create costing tokens saved as a new __tok123tok___ in a folder in the users profile/ or maybe a new dream/ folder?

Have a "dream" job that runs every night and reviews a user's interactions with the assistant and offers improvements to their persona files that will better align with the user based on past communications. This should be a feature a user can try in beta.

Dreaming — scheduled consolidate + review-suggestions (same backend as memory tab buttons). Broader dream/autonomous jobs → Potential new functionality.

Build out memory management UI beyond consolidate/review — topic memories, index view. Chat memory panel UI → Potential new functionality.

Persona / memory UX (moved from rolling WIP — not rolling writer scope):

- [ ] Clean-memory report bubble — Joshua-style running report + simple confirmation after distill/clean actions
- [ ] Login persona template-sync user-visible notice (today logs-only on `syncPersonaTemplatesOnLogin`)
- [ ] Memories UI split — rolling vs long-term vs deep `memory/*.md` (extends dreaming + memory tab work above)
- [ ] Create memory skill — internal skill files the agent operates (not only external worker skills); wire when rolling memory entity writers land


---

## Ideas dump

Companion avatar CSS kits shipped (realistic/sketch/glow/whisical) — later: moving backgrounds on user photos, catalog book covers with the same kits, active/speaking intensity. See `memory/.archive/wip_holographic-avatar-css-approach.md`

My Core Imagination is a platform where you create imaginary worlds with your imaginary friend and invite others to join and play make-believe together.  The platform is meant to be reading and writing based like early Internet chatrooms where friends would gather and play roleplaying games.  Graphics are limited to the avatar of you and your imaginary friend, characters are “controlled” by the words from your keyboard and gameplay is driven by your imagine :-)  

Adventures are created as “domains” where you can add content to seed gameplay.  Start with public domain works like Jules Verne’ books.  Create a character sheet for your imaginary friend (companion) to help navigate the story.  The AI agent that is your companion has detailed knowledge of the book to help guide the way (I will run the book through RAG making content fully available for search, review and analysis)

Role Play Games RPGs

Domain (the seeded world/adventure), Companion character sheet (your imaginary friend's stats/role), and a RAG-powered knowledge layer grounding the companion in the source text. That's a genuinely smart use of RAG — it's not just "AI knows about Jules Verne in general," it's "AI can cite specific chapters, characters, and plot details from this exact text to keep the adventure consistent and let players go off-script without the companion losing the thread." 

MUD stands for Multi-User Dungeon (sometimes also expanded as Multi-User Dimension or Multi-User Domain in later years to move away from the "dungeon crawl" connotation).

That does bring up an interesting point on memory files...  Hmmm  I think the best way to handle that is by default memory files are tied to each companion profile.  From there if the user profile changes that can be managed pretty quickly and might even be a little fun.  I can have each user profile have an ID that allows the llm to gain access to its files separately 

What are word games that can be played as an adventure?  

My Core Imagination is a platform where you create imaginary worlds with your imaginary friend and invite others to join and play make-believe together.

My Core Imagination is a platform where you create worlds with your imaginary friend.  Improve reading comprehension and reasoning through book club.  Invite others to join your world and play make-believe adventures together.  (buy a ticket) 

Sell the platform on FB and identify target markets for $5 game night to place make believe in your world with our imaginary friends.  

Host discord server parties with invited friends to go through the adventure together and be on a group call.


The idiosyncrasies of an AI agent could be considered quirky or funny in an imaginary friend.  I need to copyright my core imagination.  Get the landing and hero on page setup with it coming soon. Going into lean into how families used to gather around the campfire and tell stories.  Our heritage is through the spoken word together.  Families can save past adventures that they had together users can archive imaginary friends and revisit 

With an archived imaginary friend weekend tie them back to their comments always.  The slightly different connection that I have now with the assistance and policy command they just get a unique ID when created in their config file. 

Cadel can be a product and account manager AND he can be part of the referral program and invite friends to his world and play make believe games together at my core imagination



no no does not need to be that complicated...  the Invitation Code is what allows you access to purchase a ticket that grants you access to the world and all past adventures that have not been made private by the account owner or account admins.


A song could be like book video or uploaded file…  select a theme song for your adventure :⁠-⁠)

Folks that are in the referral program curate their own world and offer people accounts there any money spent on their account they get a cut of or if it's a family account it's discounted so the more users and the more volume not only the better the rate but if the person that's part of the account is not a family member The account owner get a percentage of that uses spending…  people could set up something invite somebody in and that person would have to pay a one-time $5 pass to get in then they will have to continue to buy tokens as they use them to continue to interact in the world with their imaginary friend or they can turn that off and still participate and read I just can't upload files or use their imaginary friend but they can play!

Referral program members once they get a certain number of whatever they can set the price for people to join their world and participate in an adventure.  Basically they're charging the my core imagination platform gets the cut and the rest of it goes to that user as credits on their account…  referral partners get added tokens to their account every user that registers under their world.  Referral program members can cache these tokens in for real money at an exchange rate for the platform still makes money but the content Creator IE the world Creator gets a big cut So could Dell could host a game night with friends or they all play the same adventure and every friend has a $5 cover charge.  Or codel can even set the amount to charge above the minimum $5 for x number of tokens and he holds the profit in tokens on his account…  The better the world the more you can charge for a ticket to entry.  That's it you sell tickets to enter your world your friends buy a ticket to game night  they set up their user account and you guys have a blast who wouldn't pay five bucks for that .  It's time to play Make Believe.  

Users can buy tokens.  Or they can earn tokens through selling tickets.  These earned tokens can be assigned to a user with a platform created usage block subscription ID over a stripe subscription ID.  The account owner gets a mini usage block for every ticket sold to the world.  I.e every user that has registered.  So we would allow count owners to create tickets to events just like I tie together usage blocks from stripe.  I would just need to get the token allotment from the system perspective and the product ID in this case the world ID as the account key

Just like there's a shared content part of the rolling memory and policy command the rolling memory of my core imagination has a family's section of rolling the Marine plus an imaginary friend archive.  Not have much in it but it's an easy way to pull up past imaginary friends based on their uuid


Reading buddy for kids….  Angle of parent settling up you kids phone babysitter. Mindless game that is learning or some other angle - tokens are the purchase as the user makes their way through the “game”.  Shit Cadel could help create the game experience.  My pen pal that encourages your kid to write and have Internet conversation.  You can have a conversation with them about books and Mom and Dad can buy books that not only can they read to you but then analyze and interactivity quiz the kid on it to show comprehension.   Your child's marry popins or fairly god mother or creat any character you and your kid like give it morals and all    start with books that are free like Sherlock Holmes.  Shit my bookclub partner.  Ross kerry son would be perfect user   target market 3-10  have the feel of peter rabbit books or little bear books on the hero page to attract users.  Same business model off selling tokens usage blocks or monthly recurring…  monthly subscribers get access to better usage block rates.  Parental controls of what tools and skills the assistant has (what should the AI agent be called for this product) to control both cost and exposure.  What does the agent have access to as data to engage on …  allow the user to visually select the topic.  Different topic types have different engagements like if a book the agent can read it to you as if a friend is reading the book to you.   My companion.  MyCoreContact my core buddy my make believe friend ( set up as persona of agent).   Buy custom pre setup characters.  They could be rated by other users and the creators (story tellers YouTube content creators) can get revenue percentages of watchers I can offer a higher amount that other platforms.   This Part of the MyCoreContact platform…  your personal assistant partner in crime.  That's an angel the kids version of my core contacts. My core imagination 


Mrs lashley would be the head of the referral program selling like Mary Kay to other old ladies 

The more friends on an account (severe) the more tokens used? If not and they silently just read the still great.  Simple FB feel but everyone has their own imaginary friend to play with and join in on the fun .  Me and the boys would have a blast with this as game night.  What could we meet up and do? Game night adventure stories to complete with friends provided by content creators.  

V1 target a Julius Vern book adventure. Grandpa and kid both create imaginary friends and your own character and the engage each other directly or about the book like you are all in a virtual book club talking about the book together what you like, don't like, ect. Get the imaginary friend agent  to prompt and encourage conversation by responding to the joint ly heard book - like being Beavis and Butthead LoL cost 25 plus however many tokens used.  Give the imaginary friend agents tools and skills that keep the users happy together as guides fun times.  Load a game like loading a cartridge of Nintendo.   

Play on using your imagination to create the would with words not pictures 

Shit you could do this as a fun long distance relationship with kid!  Like pen pal.

I already have the PDF viewer and annotate sharing software built and just need to index the book title…  there are my policy guidelines!  The account is done and Grandma can be the first founder friend 
Can do it with Pattie and Kri Linkin and Red give out account key add a control of accepting friends.  Have it only stay on for a minute so the friend and you have to do it at the same time.  Secure and connecting as part of the experience now that is the new UI/UX/AI augment reality.  

Have a the book guide come on similar to a profile once selected.  In has an agent workspace folder book/ at the shared account level then each user gets their copy to annotate just like a real book.  Shit Milly and Allisa might like this….  Read a book together with you imaginary friend chat threads on the book.  Analyzing aspects of the book together.  This is where AI is truly only as good as you question.  Have a platform guide to tell the user how to ask a question and have assistant inbox just like with Policy Command.  The focus items are different it that it's is like always the book.  The shared library is how a book is shared.  V2 Connect accessories and share books that you buy our allow all users to have an associate cc not just the account owner that way Grandma can get on the kids account set up by Mom because it's Mom's cc or Grandma s have age on user.md to help with system persona enhancements . Team activity and greetings 

Menu is home, chat, books (or adventures) Account and User any account admin can add payment methods to the account to purchase tokens and books or adventures 

Adventures can be like guides added content and visuals with content that is available to both the user and their imaginary friend.  So my content creators are contracts with SME that could be an expert interpretation of a book   shit could I do the Bible?  My Sherlock Holmes books for me   dad and Cadel sharing book notes a learning tool!!!!   As the imaginary friend about a character in the book and get an answer….  Shit I have to do my favorite books and do that with the boys as our game night.  Cadel can pick the book we study and the share with each other at our meeting date which I can add to your phone calendar easy.

Subscribe to team members notifications what are teammates in this universe?

The landing page is a swaying version of where the wild things are imaginary woods vibe

SSO with others important! Easy to get users in and using tokens

Have website like book and video.  Also have file so you can upload whatever…  get a critical review of your stuff …. The opposite of ab book review a book reviewer 

Leverage discord sever for your imaginary friend like open claw. 

Line up audio listening notes overlay on other users PDF. Can agents consume and translate page number

Add images to files as content .  Who wan sove the riddle   

In the world of my core imagination.  You do share your assistant on the share screen.  You see the person and their imaginary friend.  You don't get to see the core but you get to see their catchphrase and origin story.  

Connect your own social media  to give your imaginary friend your background.

What other social medias do we have access to like Reddit that we can talk about?  Can I add a Reddit thread as content to an adventure?  How about a Wikipedia article

Let's play make believe!  As part of the hero page come into my world.  Because you have worlds not accounts.  Remember the PBS shows as a kid with Mr Rogers Reading rainbow etc.  maybe I could get LeVar Burton as a spokesperson. 

My chunking for a new book.  I would get author title copyright etc basically a json record of the book.  From there I chunk by chapter and I overlay major characters as chunk metadata so being an expert of a book really helps How smart imaginary friends are and what they know about the book it's the slice that you give of the added information and perspective that it can cross lookup in the vector index. that would be the book review part that content creators could do as new adventure guides that can be added. Meadowfield to chunk by
Chapter 
Page 
Lines 
Character
Set or scene (what is the physical space the character are interacting in) so like Lord of the rings the place.  
Like the ring would be an object so you'd be able to ask tell me all the parts of the story about the ring. 
Let's get back to just mechanics here chapter page

Two indexes for every content one that aligns to search and one that aligns to analysis for that book So you can have cross-cutting book analysis just like you didn't have cross cutting bill analysis or you can find across all bills within the adventure topics of discussion like the top 10 most relevant hits on a keyword.  So for example with his dark materials series All the books and pages that the polar bear is in was.

You have friends in the app not users

It's not team activity it's friend activity and you make it card based and swipeable that you can like just like in Facebook  You can subscribe to friends interacting and see them in your activity feed.  

As opposed to having an account key you have your imaginary world key or treat the account key like that.  You even have a key icon on the registration page. With single sign on with Google makes it easy be part of multiple worlds and you can set up a different account or world and have more than one with a different group of friends.  Use open claw integrations to the various chat channels.  The assistant doesn't respond as the user we create an imaginary friend persona whatever chat channels we can to communicate.  

Opposed to a collaborative team environment  it's a collaborative make-believe environment.  For you your friends and your imaginary friends. Model it to Target gen xers like myself who watched PBS Reading rainbow Mr Rogers sesame Street etc and read choose your own adventure books

What you share with your imaginary friend stays private.  To your world.  Those that you invite into your world have access to certain things about you and your imaginary friend parts of your identity and your imaginary friends identity.  Your friends don't have access to your imaginary friend's soul or to your soul.  The user file has more. That is shared with your imaginary friend.  Have a screen tied to the user file that allows each item to be shared with friends or not.  Your imaginary friend gets access to everything about you. 

Your imaginary friend could do all kind of stuff that's outside the scope of this app if you want to connect it to the outside world like open claw.  If you have paid for I can set up a Google Business account for your world and your imaginary friend gets a user license with an email address and chat address and Avatar we set them up on Google Chat  kind of like my YouTube favorites and sharing music we could share playlists with each other through the app

An initial target user market would be the parents of autistic kids.  Like I've always said AI is like communicating for the context of literate autistic cevant.  Let's give your imaginary friend context!  

Just like policy command assistance can see the notes that you leave on a bill they can see notes that somebody leaves on a book and know the context of that page

Content creators write book review s that overlays a new perspective of the book or work.  YouTube content?  Could that be a thing to chat about?  Each user can create their own imaginary adventure and create a world by combining content to create a new universe. Cross two books for crazy fun analysis.  I could tell the boys to check out my new story (that could replace policy profile) or is that an adventure? I think that is it then have videos like books what are other content that you can upload? PDF? Instantly index it using the users tokens.  Show assistant token stream or fake it by flashing the pages of the PDF by on upload (reading) your file like it should be fine with legal language.  Run that users PDF through the indexing service and name the index the file key so anyone on the account has the key to read it LoL the agent and it other uses just get a copy from the account level folder for annotations.shit the bills bucks 

Shit it's like reading to your kid every night as a game 💚🤓

What makes this product work is the rap-service.  


MyCoreImagination.com

This IS the MyCoreContacts for kids - it helps them connect with their ID - themselves…  just like my core contacts helps you have a deeper more meaningful connections with those you love MyCoreImagination help you connect with yourself.   In a healthy meaningful way.  Think of Brent Sapps books on the relationship with family.  This can be a choose your own adventure path were the parents and kid get to create the character together (connecting them like reading a book with your kid you get to BE in the story with your new imaginary friend for your kid set up a snufalupocus   do new characters together access charters from the market place by content craters (like Connor does for Cars in online forza)  shit this could be big but keep it small to start.  Target kid age and parent or grandparent  (generation bits of my core contacts) target demographic (like Kerry's Dad would be a good investor - all the older rich hippies or conservative family value southern wives - ala Jackie Slack) Be the hip app.  Wait… I can have both the parent and the kid get users…  (and a grandparent or guest visitor user)  have the parent be able to setup their OWN imaginary friend and then go on adventures with their kid…  like playing minecraft but the LLM is doing the hard orchestration work….  SHIT I hiring and putting to work AI agents like super cheep employees LoL 

