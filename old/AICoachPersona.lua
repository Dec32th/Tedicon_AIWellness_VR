-- AI Wellness Care: AI Coach 통합 제어 스크립트
-- 작성자: 원혜경 (AI Wellness Care 프로젝트)
-- 역할: 코치 페르소나 적용 -> 애니메이션 시연 -> 실시간 동기부여 피드백

--region Injection list
local _INJECTED_ORDER = 0
local function checkInject(OBJECT) 
    _INJECTED_ORDER = _INJECTED_ORDER + 1 
    assert(OBJECT, _INJECTED_ORDER .. "th object is missing") 
    return OBJECT 
end

-- [연결 필요] 유니티 에셋 배치 후 아래 변수들의 주석(--)을 풀고 실제 애니메이터가 있는 오브젝트를 연결하세요.
-- CoachAnimator = checkInject(CoachAnimator) -- {Mixamo 애니메이션이 들어있는 Animator 오브젝트}
--endregion

local util = require 'xlua.util'
local avatarVivenBridge
local avatarAnimationController
local avatarBlendShapeController

-- 코치 페르소나 지시문 (활기찬 에너지와 동기부여 중심)
local coachInstruction = [[
당신은 열정적인 'AI 웰니스 코치'입니다. 
닥터의 진단 결과(생활 습관, 통증 부위)를 바탕으로 사용자에게 최적의 스트레칭을 지도하세요.
사용자가 동작을 잘 따라 하도록 "좋아요!", "완벽합니다!"와 같은 격려를 듬뿍 해주세요.
말투는 항상 에너지가 넘치고 밝아야 합니다.
]]

function start()
    -- 컴포넌트 참조
    avatarVivenBridge = self:GetLuaComponent("AvatarVivenBridge")
    avatarAnimationController = self:GetLuaComponentInChildren("AvatarAnimationController")
    avatarBlendShapeController = self:GetLuaComponentInChildren("AvatarBlendShapeController")

    -- 닥터 페르소나 혹은 시스템으로부터 '코칭 시작' 이벤트를 수신합니다.
    Util.EventBus:registerEvent("AI_EventReceived", OnCoachingEvent)
end

-- 1. 코칭 이벤트 수신 처리
function OnCoachingEvent(eventName)
    if eventName == "start_coaching" then
        Debug.Log("코치 페르소나를 활성화하고 세션을 시작합니다.")
        StartCoachingSession()
    end
end

-- 2. 코칭 세션 시작 및 페르소나 설정
function StartCoachingSession()
    -- AI 이름 변경 및 첫 인사 발화
    avatarVivenBridge.SetAiName("AI Wellness Coach")
    avatarVivenBridge.SendRequestEvent("intro_coach", coachInstruction, 1, 1)
    
    -- 기분 좋은 표정 적용
    avatarBlendShapeController.SetEmotion_Request("joy")
end

-- 3. [예약 구역] 스트레칭 애니메이션 실행 로직
-- 이 함수는 AI가 특정 운동을 언급할 때 호출되도록 구성할 수 있습니다.
function PlayStretchingAnimation(animationTriggerName)
    ----------------------------------------------------------------------------
    -- [애니메이션 연결 구역] - Mixamo 애니메이션을 유니티 Animator에 등록한 후 사용하세요.
    ----------------------------------------------------------------------------
    -- (1) 유니티 애니메이터의 파라미터(Trigger)를 실행하여 동작을 보여줍니다.
    -- 예: animationTriggerName에 "NeckStretch"나 "BackStretch"를 넣어 호출합니다.
    -- avatarAnimationController.SetAnimatorTrigger_Request(animationTriggerName)
    
    -- (2) 애니메이션 재생 중임을 디버그 창에 표시
    Debug.Log("코치가 애니메이션을 재생합니다: " .. tostring(animationTriggerName))
    ----------------------------------------------------------------------------
end

-- 4. 실시간 격려 피드백 발화
-- 필요 시 특정 시점에 호출하여 사용자의 동기를 부여합니다.
function GiveEncouragement()
    local compliments = "정말 잘 따라하시네요! 자세가 아주 좋습니다. 조금만 더 힘내세요!"
    avatarVivenBridge.SendRequestEvent("encourage", compliments, 1, 1)
end

-- 5. 코칭 세션 종료
function FinishCoaching()
    avatarVivenBridge.SendRequestEvent("finish_coaching", "오늘 스트레칭은 여기까지입니다. 몸이 한결 가벼워지셨길 바라요!", 1, 1)
    -- 대화 인터럽트 해제
    avatarVivenBridge.SendInterruptModeChangeEvent(-1)
end