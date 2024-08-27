import ContentBox from "@/components/content-box";
import IconButton from "@/components/icon-button";

export const Standing = () => {
    return (
        <ContentBox
            heading="Profile Standing"
            actions={[
                <IconButton key="question-mark">
                    <QuestionMarkIcon />
                </IconButton>,
            ]}
            items={Object.values(MOCK_STATS).map(({ key, ...stat }) => (
                <Stat key={key} {...stat} />
            ))}
        />
    );
};
