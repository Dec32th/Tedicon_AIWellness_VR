-- AI Wellness Care: 통합 시나리오 제어 스크립트
-- 작성자: 원혜경 (AI Wellness Care 프로젝트)
-- 역할: 닥터 진단(생활 습관 포함) -> 사용자 판단(상담 종료 여부) -> 코치 전환 및 이동

--region Injection list
local _INJECTED_ORDER = 0
local function checkInject(OBJECT) 
    _INJECTED_ORDER = _INJECTED_ORDER + 1 
    assert(OBJECT, _INJECTED_ORDER .. "th object is missing") 
    return OBJECT 
end

-- [연결 필요] 유니티 에셋 배치 후 인스펙터 창에서 아래 변수들의 주석(--)을 풀고 실제 오브젝트를 연결하세요.
-- DoctorGown = checkInject(DoctorGown)   -- {의사 가운 메쉬 오브젝트}
-- CoachOutfit = checkInject(CoachOutfit) -- {운동복 메쉬 오브젝트}
-- StudioPoint = checkInject(StudioPoint) -- {스튜디오 이동 목표 지점 - Empty Object}
--endregion

local util = require 'xlua.util'
local avatarVivenBridge
local avatarMoveController

-- 페르소나 설정: 생활 습관 질문 후 반드시 추가 상담 여부를 묻도록 지시
local doctorInstruction = [[
당신은 친절하고 전문적인 'AI 웰니스 닥터'입니다. 대학생인 사용자의 건강을 위해 다음 사항을 확인하세요:
1. 하루 평균 앉아있는 시간과 평소 앉는 자세 (거북목, 다리 꼬기 등)
2. 정기적인 스트레칭이나 운동 습관 여부
3. 현재 느껴지는 구체적인 통증 부위
모든 진단이 끝나면 반드시 "진단을 위한 정보는 모두 파악되었습니다. 혹시 추가적인 상담이 필요할까요?"라고 질문하여 사용자의 의사를 확인하세요.
사용자가 '아니오' 혹은 '괜찮다'고 하면 운동을 시작할 준비가 된 것으로 간주합니다.
]]

-- 상태 관리 변수
local isWaitingForDecision = false

function start()
    -- 컴포넌트 참조
    avatarVivenBridge = self:GetLuaComponent("AvatarVivenBridge")
    avatarMoveController = self:GetLuaComponent("AvatarMoveController")

    -- 상호작용 관련 이벤트 등록
    -- 1. 사용자가 상호작용을 시작(발화 감지)하면 진단 시작
    Util.EventBus:registerEvent("Avatar_AiDetectClientAudio", StartDiagnosis)
    -- 2. 사용자의 답변 내용을 실시간으로 확인하여 예/아니오 판단
    Util.EventBus:registerEvent("Avatar_ClientTranscriptReceived", OnUserResponseReceived)
end

-- 1. 진단 시작 함수 (사용자가 말을 걸면 실행)
function StartDiagnosis(id, uuid)
    if id ~= avatarVivenBridge.GetAiId() then return end
    
    avatarVivenBridge.SetAiName("AI Wellness Doctor")
    avatarVivenBridge.SendRequestEvent("start_clinic", doctorInstruction, 1, 1)
    isWaitingForDecision = true -- 상담 종료 여부를 판단하는 단계로 진입
end

-- 2. 사용자의 '예/아니오' 답변 판단 로직
function OnUserResponseReceived(textKr, textEn)
    if not isWaitingForDecision then return end

    -- "추가 상담이 필요할까요?"에 대한 답변 분석
    if string.find(textKr, "아니") or string.find(textKr, "괜찮") or string.find(textKr, "없어") then
        -- 사용자가 '아니오'라고 답함 -> 스튜디오로 이동 루틴 시작
        Debug.Log("사용자 판단: 추가 상담 불필요. 웰니스 스튜디오로 이동합니다.")
        isWaitingForDecision = false
        self:StartCoroutine(util.cs_generator(TransitionToCoachRoutine))
    elseif string.find(textKr, "응") or string.find(textKr, "어") or string.find(textKr, "네") or string.find(textKr, "예") then
        -- 사용자가 '예'라고 답함 -> 상담 지속
        Debug.Log("사용자 판단: 추가 상담 필요. 상담을 지속합니다.")
        -- 특별한 이동 없이 대화 모드 유지
    end
end

-- 3. 전환 시퀀스 코루틴 (이동 및 페르소나 변경)
function TransitionToCoachRoutine()
    -- 이동 안내 및 모델 변경 준비
    avatarVivenBridge.SendRequestEvent("move_start", "추가 상담이 필요 없으시군요. 그럼 맞춤형 운동을 위해 웰니스 스튜디오로 이동하겠습니다.", 1, 1)
    coroutine.yield(WaitForSeconds(3))

    ----------------------------------------------------------------------------
    -- [에셋 배치 후 주석 해제 구역] - 이 부분은 유니티에서 실제 오브젝트를 만든 뒤 주석(--)을 지우세요.
    ----------------------------------------------------------------------------
    -- (1) 스튜디오로 실제 이동
    -- local targetPos = StudioPoint.transform.position
    -- avatarMoveController.MoveToTargetPos(targetPos)

    -- (2) 목표 지점에 도착할 때까지 대기
    -- coroutine.yield(WaitUntil(function()
    --     return Vector3.Distance(self.transform.position, targetPos) < 0.5
    -- end))

    -- (3) 의상 시뮬레이션 (의사 가운 끄고 운동복 켜기)
    -- DoctorGown:SetActive(false)
    -- CoachOutfit:SetActive(true)
    ----------------------------------------------------------------------------

    -- 4. 코치 페르소나 적용 및 코칭 시작
    avatarVivenBridge.SetAiName("AI Wellness Coach")
    avatarVivenBridge.SendRequestEvent("start_coaching", "상담 내용을 바탕으로 당신의 앉은 자세와 통증을 고려한 맞춤형 스트레칭을 시작하겠습니다.", 1, 1)
    
    -- 대화 시스템 복구 (인터럽트 모드 해제하여 다시 대화 가능하게 함)
    avatarVivenBridge.SendInterruptModeChangeEvent(-1)
end